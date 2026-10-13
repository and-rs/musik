#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

output="${RENDER_OUTPUT:-$root/result.wav}"
if [[ "$output" != /* ]]; then
	output="$root/$output"
fi
if [[ -e "$output" ]]; then
	echo "Refusing to overwrite $output; move it aside or set RENDER_OUTPUT." >&2
	exit 1
fi

for process in scsynth sclang SuperCollider; do
	if pgrep -x "$process" >/dev/null 2>&1; then
		echo "Close the running SuperCollider session first (or run 'just stop')." >&2
		exit 1
	fi
done
if pgrep -f '[g]hci.*BootTidal.hs' >/dev/null 2>&1; then
	echo "Close the running Tidal session first (or run 'just stop')." >&2
	exit 1
fi

bpm="$(sed -n 's/^let tempoBpm = \([0-9.]*\) :: Double$/\1/p' src/main.tidal)"
bars="$(sed -n 's/^let barsPerSection = \([0-9]*\) :: Time$/\1/p' src/main.tidal)"
if [[ -z "$bpm" || -z "$bars" ]]; then
	echo "Could not read tempoBpm/barsPerSection from src/main.tidal." >&2
	exit 1
fi

# Four sections, four beats per bar, plus five seconds for startup and effect tails.
render_seconds="$(awk -v bpm="$bpm" -v bars="$bars" \
	'BEGIN { printf "%.3f", (4 * bars * 4 * 60 / bpm) + 5 }')"

tmpdir="$(mktemp -d)"
sc_pid=
cleanup() {
	status=$?
	trap - EXIT INT TERM
	if [[ -n "$sc_pid" ]] && kill -0 "$sc_pid" 2>/dev/null; then
		pkill -TERM -P "$sc_pid" 2>/dev/null || true
		kill -TERM "$sc_pid" 2>/dev/null || true
		wait "$sc_pid" 2>/dev/null || true
	fi
	rm -rf "$tmpdir"
	exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

RENDER_PATH="$output" RENDER_SECONDS="$render_seconds" \
	superdirt >"$tmpdir/superdirt.log" 2>&1 &
sc_pid=$!

ready=0
for ((i = 0; i < 1200; i++)); do
	if grep -q 'RENDER_READY' "$tmpdir/superdirt.log"; then
		ready=1
		break
	fi
	if grep -q 'ERROR:' "$tmpdir/superdirt.log"; then
		cat "$tmpdir/superdirt.log" >&2
		echo "SuperDirt failed while booting." >&2
		exit 1
	fi
	if ! kill -0 "$sc_pid" 2>/dev/null; then
		cat "$tmpdir/superdirt.log" >&2
		echo "SuperDirt exited before boot completed." >&2
		exit 1
	fi
	sleep 0.1
done
if [[ "$ready" != 1 ]]; then
	cat "$tmpdir/superdirt.log" >&2
	echo "Timed out waiting for SuperDirt to boot." >&2
	exit 1
fi

echo "SuperDirt ready; rendering four ${bars}-bar sections at ${bpm} BPM to $output"
{ expand -t 4 src/main.tidal; sleep "$render_seconds"; } | tidal
wait "$sc_pid"

if [[ ! -s "$output" ]]; then
	echo "SuperCollider did not create the WAV file." >&2
	exit 1
fi
echo "Rendered $output"
