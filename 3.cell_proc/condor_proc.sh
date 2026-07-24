#!/bin/bash

export EOSSHIP=root://eospublic.cern.ch/

RUN=$2
BRICKID=$3
BRICKFOLDER=$4
CELL=$5
CELLFOLDER=$6
xcell=$((CELL % 18 + 1))
ycell=$((CELL / 18 + 1))
PLATENUMBER=$7
PLATEFOLDER=$8
EXP_PRE=$9
EXP_DIR=$EXP_PRE/RUN$RUN/RUN1_W4_B4_SG/$BRICKFOLDER/cells/$CELLFOLDER/$BRICKFOLDER

echo "Set up SND environment"
SNDBUILD_DIR=/afs/cern.ch/user/s/snd2cern/public/SNDBUILD/sw
source /cvmfs/sndlhc.cern.ch/SNDLHC-2025/Oct7/setUp.sh
eval `alienv load -w $SNDBUILD_DIR --no-refresh sndsw/latest`
echo "Loading FEDRA"
source /afs/cern.ch/user/s/snd2cern/public/fedra/setup_new.sh

export LD_PRELOAD=/cvmfs/sndlhc.cern.ch/SNDLHC-2025/Oct7/sw/slc9_x86-64/XRootD/latest/lib/libXrdPosixPreload.so
export XROOTD_VMP=eospublic.cern.ch:/eos=/eos

MAIN_DIR=$PWD
cd $MAIN_DIR
MY_DIR=${CELL}_${PLATENUMBER}/$BRICKFOLDER
mkdir -p -v ./$MY_DIR/$PLATEFOLDER
cd $MY_DIR

# Copy raw data to local scratch for faster repeated reads during processing
echo "Copying raw plate data to local scratch..."
xrdcp -f root://eospublic.cern.ch/$EXP_DIR/$PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.raw.root ./$PLATEFOLDER/
RAW_RC=$?; echo "xrdcp raw.root exit=$RAW_RC"
[ $RAW_RC -ne 0 ] && { echo "ERROR: failed to copy raw.root"; exit 1; }
ls -lh ./$PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.raw.root || exit 1

ln -s $EXP_DIR/$BRICKFOLDER.0.0.0.set.root .
ln -s $EXP_DIR/viewsideal.rootrc ./viewsideal.rootrc
ln -s $EXP_DIR/viewsideal.sh .
ln -s $EXP_DIR/mosalignbeam.sh .
ln -s $EXP_DIR/moslink.sh .


echo "=== PROC JOB START: BRICK=$BRICKID PLATE=$PLATENUMBER CELL=$CELL xcell=$xcell ycell=$ycell ==="
echo "EXP_DIR=$EXP_DIR  DATE=$(date)"

echo "--- viewsideal $BRICKID.$PLATENUMBER.0.0 ---"
source viewsideal.sh $BRICKID $PLATENUMBER
STEP_RC=$?; echo "viewsideal exit=$STEP_RC"
[ -f "$PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.mos.root" ] || { echo "FAILED: viewsideal (mos.root not produced)"; exit 1; }

# Transfer mos.root immediately so it's safe even if later steps fail
OUT_URL="root://eospublic.cern.ch/$EXP_PRE/RUN$RUN/RUN1_W4_B4_SG/$BRICKFOLDER/cells/$CELLFOLDER/$BRICKFOLDER/$PLATEFOLDER"
echo "Transferring mos.root to $OUT_URL/"
xrdcp -f "$PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.mos.root" "$OUT_URL/$BRICKID.$PLATENUMBER.$xcell.$ycell.mos.root"
MOS_RC=$?; echo "xrdcp mos.root exit=$MOS_RC"; [ $MOS_RC -ne 0 ] && { echo "WARNING: xrdcp mos.root failed"; }

echo "--- mosalignbeam $BRICKID.$PLATENUMBER.0.0 ---"
source mosalignbeam.sh $BRICKID $PLATENUMBER
STEP_RC=$?; echo "mosalignbeam exit=$STEP_RC"

echo "--- moslink $BRICKID.$PLATENUMBER.0.0 ---"
source moslink.sh $BRICKID $PLATENUMBER
STEP_RC=$?; echo "moslink exit=$STEP_RC"

# Find the actual cp.root file produced (avoid pipes to prevent LD_PRELOAD subprocess issues)
CP_FILE=""
for f in $PLATEFOLDER/*.cp.root; do
  if [ -f "$f" ]; then
    CP_FILE="$f"
    break
  fi
done

if [ -z "$CP_FILE" ]; then
  echo "FAILED: moslink/merge (no .cp.root file found)"
  exit 1
fi
echo "Found cp.root: $(basename $CP_FILE)"

# Transfer cp.root immediately after successful production
echo "Transferring cp.root to $OUT_URL/"
xrdcp -f "$CP_FILE" "$OUT_URL/$BRICKID.$PLATENUMBER.$xcell.$ycell.cp.root"
CP_RC=$?; echo "xrdcp cp.root exit=$CP_RC"; [ $CP_RC -ne 0 ] && { echo "FAILED: xrdcp cp.root"; exit $CP_RC; }

echo "=== PROC JOB DONE: $(date) ==="