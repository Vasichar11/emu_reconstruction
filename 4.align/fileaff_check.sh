#!/bin/bash

BRICKID=$1
BRICKFOLDER="$(printf "b%0*d" 6 $BRICKID)"

while IFS=',' read -r p CELL; do
    xcell=$((CELL % 18 + 1))
    ycell=$((CELL / 18 + 1))

    folder=cell_${xcell}0_${ycell}0/$BRICKFOLDER/AFF

    base=$BRICKID.$((p+1)).0.0_$BRICKID.$p
    file_aff="$folder/$base.$xcell.$ycell.aff.par"
    file_al="$folder/$base.$xcell.$ycell.al.root"

    dest_aff="$folder/$base.0.0.aff.par"
    dest_al="$folder/$base.0.0.al.root"

    if [ -f "$file_al" ]; then
        mv "$file_aff" "$dest_aff"
        mv "$file_al" "$dest_al"
    elif [ ! -f "$dest_al" ]; then
        echo "$p, $CELL"
    fi

done < volumes_al.dat