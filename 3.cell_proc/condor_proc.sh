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
EXP_DIR=$EXP_PRE/RUN$RUN/$BRICKFOLDER/cells/$CELLFOLDER/$BRICKFOLDER

echo "Set up SND environment"
SNDBUILD_DIR=/afs/cern.ch/user/s/snd2cern/public/SNDBUILD/sw
source /cvmfs/sndlhc.cern.ch/SNDLHC-2025/Oct7/setUp.sh
eval `alienv load -w $SNDBUILD_DIR --no-refresh sndsw/latest`
echo "Loading FEDRA"
source /afs/cern.ch/user/s/snd2cern/public/fedra/setup_new.sh

export LD_PRELOAD=/cvmfs/sndlhc.cern.ch/SNDLHC-2025/Oct7/sw/slc9_x86-64/XRootD/latest/lib/libXrdPosixPreload.so
export XROOTD_VMP=eospublic.cern.ch:/eos=/eos

# === OMP override: use optimized libraries ===
# NOTE: Condor batch nodes don't have /eos FUSE mount.  The XRD posix preload
# intercepts open() but NOT openat(), and ld-linux (glibc 2.28+) uses openat()
# to resolve LD_LIBRARY_PATH.  So the dynamic linker cannot load .so files
# from /eos paths.  We must xrdcp them to a local filesystem first.
OMP_EOS_SRC=root://eospublic.cern.ch//eos/experiment/sndlhc/users/vacharit/fedra-perf/profiling_test/build_omp/lib
OMP_LIB_DIR=/tmp/fedra_omp_lib_$$
mkdir -p $OMP_LIB_DIR
echo "Copying OMP libraries to $OMP_LIB_DIR ..."
xrdcp -f $OMP_EOS_SRC/libMosaic.so    $OMP_LIB_DIR/
xrdcp -f $OMP_EOS_SRC/libAlignment.so $OMP_LIB_DIR/
# Do NOT export LD_LIBRARY_PATH — ROOT 6 auto-discovers .pcm files in LD_LIBRARY_PATH,
# causing TFile::Open() to crash on false zombie errors. Use inline LD_PRELOAD instead.
export LD_PRELOAD="$OMP_LIB_DIR/libMosaic.so:$OMP_LIB_DIR/libAlignment.so:$LD_PRELOAD"

MAIN_DIR=$PWD
cd $MAIN_DIR
MY_DIR=${CELL}_${PLATENUMBER}/$BRICKFOLDER
mkdir -p -v ./$MY_DIR/$PLATEFOLDER
cd $MY_DIR

ln -s $EXP_DIR/$PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.raw.root ./$PLATEFOLDER
ln -s $EXP_DIR/$BRICKFOLDER.0.0.0.set.root .
ln -s $EXP_DIR/viewsideal.rootrc ./viewsideal.rootrc
ln -s $EXP_DIR/viewsideal.sh .
ln -s $EXP_DIR/mosalignbeam.sh .
ln -s $EXP_DIR/moslink.sh .
ln -s $EXP_DIR/mosmerge.sh .


echo "viewsideal $BRICKID.$PLATENUMBER.0.0"
source viewsideal.sh $BRICKID $PLATENUMBER

echo "mosalignbeam $BRICKID.$PLATENUMBER.0.0"
source mosalignbeam.sh $BRICKID $PLATENUMBER

echo "moslink $BRICKID.$PLATENUMBER.0.0"
source moslink.sh $BRICKID $PLATENUMBER

mv $PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.mos.root $MAIN_DIR/$BRICKID.$PLATENUMBER.$xcell.$ycell.mos.root
mv $PLATEFOLDER/$BRICKID.$PLATENUMBER.0.0.cp.root $MAIN_DIR/$BRICKID.$PLATENUMBER.$xcell.$ycell.cp.root

# Cleanup local OMP libraries
rm -rf $OMP_LIB_DIR