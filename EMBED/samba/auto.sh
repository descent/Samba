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

    # create a file was called "python_for_build"
    touch $TARGET/Python-2.7.12/python_for_build
    chmod 777 $TARGET/Python-2.7.12/python_for_build

    CC=arm-linux-gnueabihf-gcc-4.8.5 \
       ./configure \
       --host=armeb-linux \
       --build=i686-linux-gnu \
       --prefix=$PYTHON_OBJ/ \
       --disable-ipv6 \
       --enable-shared \
       ac_cv_file__dev_ptmx=yes \
       ac_cv_file__dev_ptc=no \
       ac_cv_have_long_long_format=yes \
       --enable-unicode \
       --with-pydebug \
       --without-pymalloc \
       PYTHON_FOR_BUILD=$TARGET/Python-2.7.12/python_for_build \

    make
    make install
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
    cp $PATCH/ldb_version.h ./source3/include/autoconf/

    export PATH=$SAMBA/bin/default/source4/heimdal_build/:$PATH
    export LD_LIBRARY_PATH=$PYTHON_OBJ/lib/:$LD_LIBRARY_PATH
    CC=arm-linux-gnueabihf-gcc-4.8.5 \
        AR=arm-linux-gnueabihf-ar \
        CPP=arm-linux-gnueabihf-cpp \
        RANLIB=arm-linux-gnueabihf-gcc-ranlib  \
        CFLAGS="-I$PYTHON_OBJ/include/python2.7 -I$SAMBA/lib/talloc/ -I$SAMBA/lib/tevent -I$SAMBA/lib/tdb/include -I$SAMBA/lib/ldb/include/ -I$SAMBA/lib/ldb/ -I$SAMBA/source3/include/autoconf/" \
        LIBDIR="-L$PYTHON_OBJ/lib/" \
        python_LDFLAGS="-L$PYTHON_OBJ/lib/ -lpython2.7" \
        python_LIBDIR="$PYTHON_OBJ/lib/" \
        ./buildtools/bin/waf \
        configure \
        --prefix=$SAMBA_OBJ/ \
        --cross-compile \
        --cross-answers=arm.txt \
        --hostcc=gcc \
        --without-ads \
        --without-pam \
        --without-ldap \
        --without-utmp \
        --without-cluster-support \
        --without-acl-support \
        --without-winbind \
        --without-dnsupdate \
        --without-dmapi \
        --enable-debug \
        --enable-selftest \
        --disable-iprint \
        --disable-gnutls \
        --disable-rpath \
        --disable-rpath-install \
        --builtin-libraries=talloc,pytalloc-util \
        --bundled-libraries=talloc,pytalloc-util,tdb,tevent,ldb \

    make
    make install
fi

