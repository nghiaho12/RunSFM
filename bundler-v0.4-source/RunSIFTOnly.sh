#!/bin/bash
#

# Set this variable to your base install path (e.g., /home/foo/bundler)
# BASE_PATH="TODO"
BASE_PATH=$(dirname $(which $0));

if [ "$BASE_PATH" = "TODO" ]
then
    echo "Please modify this script (RunBundler.sh) with the base path of your bundler installation.";
    exit;
fi

RECOVERY_MODE=0
while getopts ":r" opt; do
	case $opt in
	r)
		echo "[RunSIFTOnly] Attempting to recover/resume from last unfinished run ..." >&2
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

EXTRACT_FOCAL=$BASE_PATH/bin/extract_focal.pl

OS=`uname -o`

if [ "$OS" = "Cygwin" ]
then
    MATCHKEYS=$BASE_PATH/bin/KeyMatchFull.exe
    BUNDLER=$BASE_PATH/bin/Bundler.exe
else
	MATCHKEYS=$BASE_PATH/../SiftMatcher/bin/Release/SiftMatcher
	EXTRACTKEYS=$BASE_PATH/../RunCmdParallel/bin/Release/RunCmdParallel
    BUNDLER=$BASE_PATH/bin/bundler
fi

TO_SIFT=$BASE_PATH/bin/ToSift.sh

IMAGE_DIR="."

if [ $RECOVERY_MODE -eq 0 ]
then
	rm -f ExtractFocal.done
	rm -f SIFT_extraction.done
	rm -f SIFT_matching.done
fi

# Rename ".JPG" to ".jpg"
for d in `ls -1 $IMAGE_DIR | egrep ".JPG$"`
do 
    mv $IMAGE_DIR/$d $IMAGE_DIR/`echo $d | sed 's/\.JPG/\.jpg/'`
done

# Create the list of images
if [ $RECOVERY_MODE -eq 0 -o \( $RECOVERY_MODE -eq 1 -a ! -f ExtractFocal.done \) ]
then
	find $IMAGE_DIR -maxdepth 1 | egrep ".jpg$" | sort > list_tmp.txt
	$EXTRACT_FOCAL list_tmp.txt

	ret=$?

	if [ $ret -eq 0 ]
	then
		echo 1 > ExtractFocal.done
	else
		echo "Failed to extract focal length from images :("
		exit 1
	fi

	cp prepare/list.txt .
else
	echo "Focal has been extracted, skipping ..."
fi

# Run the ToSift script to generate a list of SIFT commands
if [ $RECOVERY_MODE -eq 0 -o \( $RECOVERY_MODE -eq 1 -a ! -f SIFT_extraction.done \) ]
then
	rm -f sift.txt

	if [ $RECOVERY_MODE -eq 1 ]
	then
		$TO_SIFT -r > sift.txt 
	else
		$TO_SIFT > sift.txt 
	fi

	# Execute the SIFT commands
	# sh sift.txt
	$EXTRACTKEYS sift.txt $SIFTKEY_CORES

	ret=$?

	if [ $ret -eq 0 ]
	then
		echo 1 > SIFT_extraction.done
	else
		echo "Failed to extract SIFT features :("
		exit 1
	fi
else
	echo "SIFT extraction done, skipping ..."
fi

if [ $RECOVERY_MODE -eq 0 -o \( $RECOVERY_MODE -eq 1 -a ! -f SIFT_matching.done \) ]
then
	# Match images (can take a while)
	# echo "[- Matching keypoints (this can take a while) -]"
	sed 's/\.jpg$/\.key/' list_tmp.txt > list_keys.txt

	if [ $RECOVERY_MODE -eq 1 ]
	then 
		$MATCHKEYS -r -s $MAX_MATCHING_SEQ list_keys.txt matches.init.txt
	else
		$MATCHKEYS -s $MAX_MATCHING_SEQ list_keys.txt matches.init.txt
	fi

	ret=$?

	if [ $ret -eq 0 ]
	then
		echo 1 > SIFT_matching.done
	else
		echo "Failed to do SIFT matching :("
		exit 1
	fi
else
	echo "SIFT matching done, skipping ..."
fi

exit 0
