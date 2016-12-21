#!/bin/bash
CURDIR=$PWD
PACKAGE=$CURDIR/PACKAGE
PATCH=$CURDIR/PATCH
TARGET=$CURDIR/TARGET
OBJ=$CURDIR/OBJ
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

if [ ! -d "$OBJ" ]; then
	mkdir $OBJ
fi

echo "************ samba-4.1.5.tar.gz ***********************"
if [ ! -d $SAMBA ]; then
    cd $PACKAGE
    tar xvf "samba-4.1.5.tar.gz" -C $TARGET

    cd $SAMBA/
    cp $PATCH/arm.txt .

    # Patch file for Embedded system
    # Ref:
    # https://git.busybox.net/buildroot/diff/package/samba4?id=dee1cf0cdf9db351fd94ccd864e09b3f1ec122f9

    patch -Np1 -i $PATCH/samba4-0001-1-build-don-t-execute-tests-summary.c.patch
    patch -Np1 -i $PATCH/samba4-0001-2-build-don-t-execute-tests-summary.c.patch
    patch -Np1 -i $PATCH/samba4-0002-build-don-t-execute-statfs-and-f_fsid-checks.patch
    patch -Np1 -i $PATCH/samba4-0003-build-find-FILE_OFFSET_BITS-via-array.patch
    patch -Np1 -i $PATCH/samba4-0004-build-allow-some-python-variable-overrides.patch
    patch -Np1 -i $PATCH/samba4-0005-1-builtin-heimdal-external-tools.patch
    patch -Np1 -i $PATCH/samba4-0005-2-builtin-heimdal-external-tools.patch

    # Patch file for Embedded system
    # Copy from samba4 which compile on X86
    mkdir ./bin/default/source4/heimdal_build -p
    cp $PATCH/asn1_compile ./bin/default/source4/heimdal_build
    cp $PATCH/compile_et   ./bin/default/source4/heimdal_build

    # Create a ldb_version.h and patch it
    mkdir $SAMBA/source3/include/autoconf
    cp $PATCH/ldb_version.h   ./source3/include/autoconf/

    export PATH=/home/freeman/test/1/Python/X86/python/OBJ/bin:$SAMBA/bin/default/source4/heimdal_build/:$PATH
    export LD_LIBRARY_PATH=/home/freeman/test/1/Python/X86/python/OBJ/lib:/home/freeman/test/1/Python/EMBED/python/OBJ/lib/:$LD_LIBRARY_PATH
    CC=arm-linux-gnueabihf-gcc-4.8.5 \
        AR=arm-linux-gnueabihf-ar \
        CPP=arm-linux-gnueabihf-cpp \
        RANLIB=arm-linux-gnueabihf-gcc-ranlib  \
        PYTHON=/home/freeman/test/1/Python/X86/python/OBJ/bin/python \
        CFLAGS="-I/home/freeman/test/1/Python/EMBED/python/OBJ/include/python2.7 -I$SAMBA/lib/talloc/ -I$SAMBA/lib/tevent -I$SAMBA/lib/tdb/include -I$SAMBA/lib/ldb/include/ -I$SAMBA/lib/ldb/ -I$SAMBA/source3/include/autoconf/" \
        LIBDIR="-L/home/freeman/test/1/Python/EMBED/python/OBJ/lib/" \
        PYTHON_CONFIG="/home/freeman/test/1/Python/X86/python/OBJ/bin/python-config" \
        python_LDFLAGS="-L/home/freeman/test/1/Python/EMBED/python/OBJ/lib/ -lpython2.7" \
        python_LIBDIR="/home/freeman/test/1/Python/EMBED/python/OBJ/lib/" \
        ./buildtools/bin/waf \
        configure \
        --prefix=$OBJ/ \
        --cross-compile \
        --cross-answers=arm.txt \
        --hostcc=gcc \
        --disable-rpath \
        --disable-rpath-install \
        --disable-iprint \
        --without-pam \
        --without-dmapi \
        --without-ldap \
        --without-cluster-support \
        --enable-debug \
        --enable-selftest \
        --disable-gnutls \
        --builtin-libraries=talloc,pytalloc-util \
        --bundled-libraries=talloc,pytalloc-util,tdb,tevent,ldb \

    make
    make install
fi

