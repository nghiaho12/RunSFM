#!/bin/bash
#
# RunBundler.sh
#   copyright 2008 Noah Snavely
#
# A script for preparing a set of image for use with the Bundler 
# structure-from-motion system.
#
# Usage: RunBundler.sh [image_dir]
#
# The image_dir argument is the directory containing the input images.
# If image_dir is omitted, the current directory is used.
#

# Modified by Nghia Ho

# Set this variable to your base install path (e.g., /home/foo/bundler)
# BASE_PATH="TODO"
BASE_PATH=$(dirname $(which $0));

if [ $BASE_PATH == "TODO" ]
then
    echo "Please modify this script (RunBundler.sh) with the base path of your bundler installation.";
    exit;
fi

OS=`uname -o`

if [ $OS == "Cygwin" ]
then
    MATCHKEYS=$BASE_PATH/bin/KeyMatchFull.exe
    BUNDLER=$BASE_PATH/bin/Bundler.exe
else
	MATCHKEYS=$BASE_PATH/../SiftMatcher/bin/Release/SiftMatcher
	EXTRACTKEYS=$BASE_PATH/../RunCmdParallel/bin/Release/RunCmdParallel
    BUNDLER=$BASE_PATH/bin/bundler
fi

RECOVERY_MODE=0
while getopts ":r" opt; do
	case $opt in
	r)
		echo "[RunBundlerOnly] Attempting to recover from last failed run ..." >&2
		RECOVERY_MODE=1
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
	esac
done

# Generate the options file for running bundler 
mkdir bundle
rm -f options.txt

echo "--match_table matches.init.txt" >> options.txt
echo "--output bundle.out" >> options.txt
echo "--output_all bundle_" >> options.txt
echo "--output_dir bundle" >> options.txt
echo "--variable_focal_length" >> options.txt
echo "--use_focal_estimate" >> options.txt
echo "--constrain_focal" >> options.txt
echo "--constrain_focal_weight 0.0001" >> options.txt
echo "--estimate_distortion" >> options.txt
echo "--run_bundle" >> options.txt

# Run Bundler!

if [ $RECOVERY_MODE -eq 1 ]
then
	if [ -f bundle.done ]
	then
		echo "Bundler completed ... skipping"
		exit 0;
	fi
fi

# This file is used for recovery support. Lets the main script know whether this bundle is completed or not
rm -f bundle.done

echo "[- Running Bundler -]"
rm -f constraints.txt
rm -f pairwise_scores.txt
$BUNDLER list.txt --options_file options.txt > bundle/out

echo "[- Done -]"

echo 1 > bundle.done
