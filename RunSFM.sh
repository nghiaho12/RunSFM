#!/bin/bash

# Call this script in the current directory where all the images are

# Usage: RunSFM.sh [IMAGES_PER_CLUSTER=100] [CPU_CORES=8] [MAX_MATCHING_SEQ=-1]
# IMAGES_PER_CLUSTER is used by CMVS/PMVS2
# CPU_CORES is used by CMVS/PMVS2
# MAX_MATCHING_SEQ is used by SiftMatcher to limit the number of images to match against, useful if the images were taken sequentially (eg. video) 

# Defaults
IMAGES_PER_CLUSTER=100
CPU_CORES=8
MAX_MATCHING_SEQ=-1
SIFTKEY_CORES=1 # For big images and limited amount of RAM

export SIFTKEY_CORES

ARGC=$#  # Number of args, not counting $0

if [ $ARGC -ge 2 ]
then
    IMAGES_PER_CLUSTER=$1
fi

if [ $ARGC -ge 3 ]
then
    CPU_CORES=$2
fi

if [ $ARGC -ge 4 ]
then
    MAX_MATCHING_SEQ=$3
fi

# Make this global, so RunBundler.sh can access it
export MAX_MATCHING_SEQ

BASE_PATH=$(dirname $(which $0));
BUNDLER_PATH=$BASE_PATH/bundler-v0.4-source
CMVS_PATH=$BASE_PATH/cmvs/program/main

$BUNDLER_PATH/RunBundler.sh .
$BUNDLER_PATH/bin/Bundle2PMVS list.txt bundle/bundle.out
bash pmvs/prep_pmvs.sh $BUNDLER_PATH
$CMVS_PATH/cmvs pmvs/ $IMAGES_PER_CLUSTER $CPU_CORES
$CMVS_PATH/genOption pmvs/

for i in {0..9999}
do
	file=`printf "option-%04d" $i`

    if [ -f pmvs/$file ] 
	then
		$CMVS_PATH/pmvs2 pmvs/ $file
	else
		break
	fi
done

echo "-------------------------------------------"
echo "The models can be found in pmvs/models"
echo 'Enjoy!'
