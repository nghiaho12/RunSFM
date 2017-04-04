#!/bin/bash

all_good=1

hash mogrify> /dev/null
if [ $? -eq 1 ]; then
    echo "ImageMagick installed ... NO"
	all_good=0
else
	echo "ImageMagick installed ... YES"
fi

gcc dummy.c -o dummy -lXext 2> /dev/null
if [ $? -eq 1 ]; then
    echo "libXext installed ... NO"
	all_good=0
else
    echo "libXext installed ... YES"
fi

gcc dummy.c -o dummy -lX11 2> /dev/null
if [ $? -eq 1 ]; then
    echo "libX11 installed ... NO"
	all_good=0
else
    echo "libX11 installed ... YES"
fi

gcc dummy.c -o dummy -ljpeg 2> /dev/null
if [ $? -eq 1 ]; then
    echo "libjpeg installed ... NO"
	all_good=0
else
    echo "libjpeg installed ... YES"
fi

gcc dummy.c -o dummy -lgfortran 2> /dev/null
if [ $? -eq 1 ]; then
    echo "gfortran installed ... NO"
	all_good=0
else
    echo "gfortran installed ... YES"
fi

gcc dummy.c -o dummy -lminpack 2> /dev/null
if [ $? -eq 1 ]; then
    echo "minpack installed ... NO"
	all_good=0
else
    echo "minpack installed ... YES"
fi

gcc dummy.c -o dummy -llapack 2> /dev/null
if [ $? -eq 1 ]; then
    echo "lapack installed ... NO"
	all_good=0
else
    echo "lapack installed ... YES"
fi

gcc dummy.c -o dummy -lblas 2> /dev/null
if [ $? -eq 1 ]; then
    echo "blas installed ... NO"
	all_good=0
else
    echo "blas installed ... YES"
fi

gcc dummy.c -o dummy -lz 2> /dev/null
if [ $? -eq 1 ]; then
    echo "zlib installed ... NO"
	all_good=0
else
    echo "zlib installed ... YES"
fi

gcc dummy.c -o dummy -latlas 2> /dev/null
if [ $? -eq 1 ]; then
    echo "atlas installed ... NO"
	all_good=0
else
    echo "atlas installed ... YES"
fi

g++ test_boost.cpp -o test_boost 2> /dev/null
if [ $? -eq 1 ]; then
    echo "boost installed ... NO"
	all_good=0
else
    echo "boost installed ... YES"
fi

if [ $all_good -eq 0 ]; then
	echo ""
	echo "Hmmm it seems you might be missing some required programs/libraries."
	echo "Check your package manager."
	exit 1
fi

exit 0
