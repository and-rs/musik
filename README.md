# TidalCycles + SuperCollider

This flake provides TidalCycles, SuperCollider, and a SuperDirt starter on Apple Silicon Macs and Linux (`x86_64` and `aarch64`). The first `nix develop path:.` downloads SuperCollider on macOS or builds its Linux package, and builds the Tidal Haskell environment.

On Linux, SuperCollider needs access to an audio backend supported by its build (JACK or ALSA). For PipeWire systems, make sure JACK compatibility is available.

## One-time setup

1. From this directory, run `nix develop path:.`.
2. In that shell, run `scide` to open SuperCollider.
3. In the SuperCollider editor, evaluate this once with **Cmd+Return** on macOS or **Ctrl+Return** on Linux:

   ```supercollider
   Quarks.install("SuperDirt");
   ```

4. Restart SuperCollider after the install completes.

## Make some sound

In one terminal, from this directory:

```sh
nix develop path:.
superdirt
```

This boots the audio server and SuperDirt using [`superdirt.scd`](superdirt.scd). Leave it running.

In a second terminal:

```sh
nix develop path:.
tidal
```

At the `tidal>` prompt, try:

```haskell
d1 $ sound "bd sn"
```

Type `hush` to stop the patterns. Run `just stop` to stop all SuperCollider processes and Tidal REPLs using `BootTidal.hs` on this machine.

## What Nix manages

- TidalCycles and its GHC environment are pinned by `flake.lock`.
- SuperCollider 3.14.1 is the official universal macOS app, wrapped as a Nix derivation with a pinned SHA-256 hash. Linux uses the source-built SuperCollider 3.14.1 package from the pinned nixpkgs revision.
- SuperDirt is installed once through SuperCollider's Quarks system and lives in your user SuperCollider configuration.
