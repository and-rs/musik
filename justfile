# Stop all SuperCollider processes and Tidal REPLs using BootTidal.hs.
stop:
    -pkill -TERM -x SuperCollider
    -pkill -TERM -x scide
    -pkill -TERM -x sclang
    -pkill -TERM -x '[.]sclang-wrapped'
    -pkill -TERM -x scsynth
    -pkill -TERM -x '[.]scsynth-wrappe'
    -pkill -TERM -f '[g]hci.*BootTidal.hs'
