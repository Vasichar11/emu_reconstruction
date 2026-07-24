#!/bin/bash

BRICKID=$1
BRICKFOLDER="$(printf "b%0*d" 6 $BRICKID)"
# Read plate,cell pairs from volumes.dat
while IFS=',' read -r p CELL; do
    plate=$(printf "p%03d" $p)
    xcell=$((CELL % 18 + 1))
    ycell=$((CELL / 18 + 1))
    folder=cell_${xcell}0_${ycell}0/$BRICKFOLDER
    base="$folder/$plate/$BRICKID.$p.$xcell.$ycell"
    file_cp="${base}.cp.root"
    dest_base="$folder/$plate/$BRICKID.$p.0.0"
    if [ -f "$file_cp" ]; then
        mv "${base}.mos.root" "$dest_base.mos.root"
        mv "$file_cp" "$dest_base.cp.root"
    elif [ ! -f "$dest_base.cp.root" ]; then
        echo "$p, $CELL"
    fi
done < volumes.dat