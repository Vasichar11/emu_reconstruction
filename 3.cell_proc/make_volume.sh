BRICKID=$1
BRICKFOLDER="$(printf "b%0*d" 6 $BRICKID)"

# === CELL FILTER LIMITS (comment all to disable filtering) ===
#XPOS_MIN=5000
#XPOS_MAX=35000
#YPOS_MIN=75000
#YPOS_MAX=125000

mkdir report_trk
for CELL in $(seq 0 323); do
  xcell=$(((CELL % 18 + 1) * 10))
  ycell=$(((CELL / 18 + 1) * 10))
  xpos=$((xcell * 1000))
  ypos=$((ycell * 1000))
  
  # Apply filter only if limits are defined
  if [ -n "$XPOS_MIN" ] && [ -n "$XPOS_MAX" ] && [ -n "$YPOS_MIN" ] && [ -n "$YPOS_MAX" ]; then
    if [ $xpos -lt $XPOS_MIN ] || [ $xpos -gt $XPOS_MAX ] || [ $ypos -lt $YPOS_MIN ] || [ $ypos -gt $YPOS_MAX ]; then
      continue
    fi
  fi
  folder=cell_${xcell}_${ycell}

  if [ ! -d "$folder" ]; then
    echo "create new folder $folder"
    cp -r cell_template $folder
    cd $folder/$BRICKFOLDER
  else
    echo "$folder already exist"
    cd $folder/$BRICKFOLDER
  fi

  sed -i "s/XPOS/$xpos/;s/YPOS/$ypos/" viewsideal.rootrc
  sed -i "s/XPOS/$xpos/;s/YPOS/$ypos/" track_realign.rootrc
  sed -i "s/XPOS/$xpos/;s/YPOS/$ypos/" track_unbend.rootrc
  sed -i "s/XPOS/$xpos/;s/YPOS/$ypos/" track_full.rootrc
  
  cd ../../
done
