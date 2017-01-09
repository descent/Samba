#!/bin/bash
CURDIR=$PWD
PACKAGE=$CURDIR/PACKAGE
PATCH=$CURDIR/PATCH
TARGET=$CURDIR/TARGET
OBJ=$CURDIR/OBJ
SAMBA_OBJ=$OBJ/SAMBA_OBJ
PYTHON_OBJ=$OBJ/PYTHON_OBJ
SAMBA=$TARGET/samba-4.1.5

if [ ! -d "$PACKAGE" ]; then
	mkdir $PACKAGE
fi

if [ ! -d "$PATCH" ]; then
	mkdir $PATCH
fi

if [ ! -d "$TARGET" ]; then
	mkdir $TARGET
fi

if [ ! -d "$SAMBA_OBJ" ]; then
	mkdir $SAMBA_OBJ
fi

if [ ! -d "$PYTHON_OBJ" ]; then
	mkdir $PYTHON_OBJ
fi

echo "************ Python-2.7.12.tgz  ***********************"
if [ ! -d $TARGET/Python-2.7.12 ]; then
    cd $PACKAGE
    tar xvf "Python-2.7.12.tgz" -C $TARGET

    cd $TARGET/Python-2.7.12/

    ./configure \
       --prefix=$PYTHON_OBJ/ \
       --enable-shared \

    make
    make install
fi

echo "************ samba-4.1.5.tar.gz ***********************"
if [ ! -d $SAMBA ]; then
    cd $PACKAGE
    tar xvf "samba-4.1.5.tar.gz" -C $TARGET

    cd $SAMBA/


    export PATH=$PYTHON_OBJ/bin/:$PATH
    export LD_LIBRARY_PATH=$PYTHON_OBJ/lib/:$LD_LIBRARY_PATH

    ./buildtools/bin/waf \
        configure \
        --prefix=$SAMBA_OBJ/ \

    make
    make install
fi

