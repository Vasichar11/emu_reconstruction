#!/bin/bash
# Generate per-plate cell list files from volumes.dat for plate-level submission.
#
# volumes.dat format: one row per (plate, cell) → "PLATENUMBER CELL"
#   (or "PLATENUMBER, CELL" with comma — both supported)
#
# Outputs:
#   plates.dat       — unique plate numbers (1 column) for queue
#   cells_pNNN.dat   — one file per plate with its cell list (1 column)

set -e
SRC=${1:-volumes.dat}

if [ ! -f "$SRC" ]; then
  echo "Usage: $0 [volumes.dat]"
  echo "ERROR: $SRC not found"
  exit 1
fi

# Normalize: turn possible commas into spaces, then take fields 1 and 2
NORM=$(mktemp)
tr ',' ' ' < "$SRC" | awk 'NF>=2 {print $1, $2}' > $NORM

# Unique plates → plates.dat
awk '{print $1}' $NORM | sort -un > plates.dat
N_PLATES=$(wc -l < plates.dat)
echo "Wrote plates.dat with $N_PLATES unique plates"

# Per-plate cell lists
rm -f cells_p*.dat
while read -r PLATE CELL; do
  FNAME=$(printf "cells_p%03d.dat" $PLATE)
  echo "$CELL" >> $FNAME
done < $NORM

TOTAL_CELLS=$(wc -l $NORM | awk '{print $1}')
echo "Wrote $(ls cells_p*.dat | wc -l) per-plate files, $TOTAL_CELLS total cells"
echo ""
echo "Sample (first 3 plates):"
head -3 plates.dat | while read p; do
  F=$(printf "cells_p%03d.dat" $p)
  echo "  plate $p: $(wc -l < $F) cells"
done

rm -f $NORM
