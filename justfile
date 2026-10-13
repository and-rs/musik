# Stop all SuperCollider processes and Tidal REPLs using BootTidal.hs.
stop:
  -pkill -TERM -x SuperCollider
  -pkill -TERM -x scide
  -pkill -TERM -x sclang
  -pkill -TERM -x '[.]sclang-wrapped'
  -pkill -TERM -x scsynth
  -pkill -TERM -x '[.]scsynth-wrappe'
  -pkill -TERM -f '[g]hci.*BootTidal.hs'

# Boots SuperDirt, loads Tidal, plays the one-shot arrangement, and writes result.wav.
render:
  nix develop path:. --command bash scripts/render.sh

mp3:
  ffmpeg -i result.wav -c:a libmp3lame -b:a 320k result.mp3
