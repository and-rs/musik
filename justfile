# Stop all SuperCollider processes and Tidal REPLs using BootTidal.hs.
stop:
    -pkill -TERM -x SuperCollider
    -pkill -TERM -x sclang
    -pkill -TERM -x scsynth
    -pkill -TERM -f '[g]hci.*BootTidal.hs'
