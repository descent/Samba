#!/bin/bash
CURDIR=$PWD
PACKAGE=$CURDIR/PACKAGE
PATCH=$CURDIR/PATCH
TARGET=$CURDIR/TARGET
OBJ=$CURDIR/OBJ

if [ ! -d "$PACKAGE" ]; then
	mkdir $PACKAGE
fi

if [ ! -d "$PATCH" ]; then
	mkdir $PATCH
fi

if [ ! -d "$TARGET" ]; then
	mkdir $TARGET
fi

if [ ! -d "$OBJ" ]; then
	mkdir $OBJ
fi

echo "************ samba-4.0.1.tar.gz ***********************"
if [ ! -d $TARGET/samba-4.0.1 ]; then
    cd $PACKAGE
    tar xvf "samba-4.0.1.tar.gz" -C $TARGET

    cd $TARGET/samba-4.0.1/
    cp $PATCH/arm.txt .

    export PATH=/opt/toolchains/stbgcc-4.8-1.5/python-runtime/bin:$PATH
    CC=arm-linux-gnueabihf-gcc-4.8.5 \
        AR=arm-linux-gnueabihf-ar \
        CPP=arm-linux-gnueabihf-cpp \
        RANLIB=arm-linux-gnueabihf-gcc-ranlib  \
        PYTHON=/opt/toolchains/stbgcc-4.8-1.5/python-runtime/bin/python  \
        ./buildtools/bin/waf \
        configure \
        --prefix=$OBJ/ \
        --cross-compile \
        --cross-answers=arm.txt \



    make
    make install
fi
