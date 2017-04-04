#!/bin/bash
#
# ToSift.sh
# Create a script for extracting sift features from a set of images

# Set this variable to your base install path (e.g., /home/foo/bundler)
BIN_PATH=$(dirname $(which $0));

IMAGE_DIR="."

OS=`uname -o`

if [ $OS == "Cygwin" ]
then
    SIFT=$BIN_PATH/siftWin32.exe
else
    SIFT=$BIN_PATH/sift
fi

if [ -e $SIFT ]
then 
:
else
    echo "[ToSift] Error: SIFT not found.  Please install SIFT to $BIN_PATH" > /dev/stderr
	exit 1
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

for d in `ls -1 $IMAGE_DIR | egrep "jpg$"`
do 
    pgm_file=$IMAGE_DIR/`echo $d | sed 's/jpg$/pgm/'`
    key_file=$IMAGE_DIR/`echo $d | sed 's/jpg$/key/'`

	if [ $RECOVERY_MODE -eq 1 ]
	then
		gzip -t $key_file.gz 2> /dev/null
		ret=$?

		if [ $ret -eq 0 ]
		then
			continue
		fi
	fi

    echo "mogrify -format pgm $IMAGE_DIR/$d; $SIFT < $pgm_file > $key_file; rm $pgm_file; gzip -f $key_file"
done
