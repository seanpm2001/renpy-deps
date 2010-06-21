#!/bin/bash

SOURCE=`dirname "$0"`
PWD=`pwd`
BUILD=$PWD/build
INSTALL=$PWD/install
export PATH="$INSTALL/bin:$PATH"

CP='cp -pR'

echo
echo Source: $SOURCE
echo Build: $BUILD
echo Install: $INSTALL
echo

mkdir -p $BUILD
mkdir -p $INSTALL

export CC=${CC:=gcc}
export CXX=${CXX:=g++}
export LD=${LD:=gcc}
export CXXLD=${CXXLD:=g++}

export CFLAGS="$CFLAGS -O3 -I$INSTALL/include"
export CXXFLAGS="$CXXFLAGS -O3 -I$INSTALL/include"
export LDFLAGS="$LDFLAGS -O3 -L$INSTALL/lib"

if [ "x$MSYSTEM" != "x" ]; then
  export CFLAGS="$CFLAGS -fno-strict-aliasing"
  export CXXFLAGS="$CXXFLAGS -fno-strict-aliasing"
fi

export LD_LIBRARY_PATH="$INSTALL/lib"
export DYLIB_LIBRARY_PATH="$INSTALL/lib"
export DYLD_FRAMEWORK_PATH="$INSTALL/frameworks"

export SED=sed
export RENPY_DEPS_INSTALL=$INSTALL

try () {
    "$@" || exit -1
}

libtool() {
    cp /usr/local/bin/libtool .
}

cd $BUILD

if [ `uname` = 'Darwin' ]; then
    MAC=yes
else
    MAC=no
fi



# try cp "$SOURCE/gcc_version.c" "$BUILD"
# try gcc -c "$BUILD/gcc_version.c"

if [ \! -e built.zlib ]; then
   try tar xvzf "$SOURCE/zlib-1.2.3.tar.gz"
   try cd "$BUILD/zlib-1.2.3"
   try ./configure --prefix="$INSTALL" --shared
   try make 
   try make install
   cd "$BUILD"
   touch built.zlib
fi

if [ \! -e built.bz2 ]; then

    try cp -Rp "$SOURCE/bzip2-1.0.3" "$BUILD/bzip2-1.0.3"
    try cd "$BUILD/bzip2-1.0.3"

    try make CC="$CC" LD="$LD" CXX="$CXX" CXXLD="$CXXLD"
    try make install PREFIX="$INSTALL"
    try cd "$BUILD"
    try touch built.bz2
fi

if [ \! -e built.python ]; then

    try tar xzf "$SOURCE/Python-2.6.5.tgz" 
    try cd "$BUILD/Python-2.6.5"
    
    # try patch -p0 < "$SOURCE/python-long-double.diff"

    # Seriously? /usr/bin/arch is hard-coded in on mac?
    try sed -e sX/usr/bin/archXarchXg < configure > configure.sed
    try cat configure.sed > configure
    
    if [ $MAC = "yes" ]; then
        try ./configure --prefix="$INSTALL" --enable-framework="$DYLD_FRAMEWORK_PATH" 
    else
        try ./configure --prefix="$INSTALL" --enable-shared
    fi
    try make
    try make install
    try cd "$BUILD"
    try touch built.python
fi

# unset MACOSX_DEPLOYMENT_TARGET

if [ $MAC = "yes" -a \! -e built.pyobjc ]; then

    try tar xvzf "$SOURCE/pyobjc-1.4.tar.gz"
    try cd pyobjc-1.4

    try cp "$SOURCE/pyobjc.setup.py" "setup.py"
    try cp "$SOURCE/gen_all_protocols.py" Scripts
    try cp "$SOURCE/cocoa_generator.py" Scripts/CodeGenerators

    try python setup.py build
    try python setup.py install 

    # try rm -Rf source-deps/py2app-source
    # try cp -Rp "$SOURCE/py2app" source-deps/py2app-source
    
    # try rm -Rf source-deps/py2app-source/src/macholib
    # try cp -Rp "$SOURCE/macholib/macholib" source-deps/py2app-source/src/macholib
    
    # try cd source-deps/py2app-source
    # try python setup.py install
    # try cd tools/py2applet
    # try python setup.py install

    try cd "$BUILD"
    try touch built.pyobjc

fi

if [ $MAC = "yes" -a \! -e built.py2app ]; then
    cp "$SOURCE/ez_setup.py" . 
    try python ez_setup.py -U setuptools
    
    try cp -Rp "$SOURCE/macholib" .
    try cd macholib 
    try python setup.py install
    try cd ..

    try "$DYLD_FRAMEWORK_PATH/Python.framework/Versions/2.6/bin/easy_install" -U py2app
    try touch built.py2app
fi



if [ $MAC = "yes" ]; then
    ln -s "$DYLD_FRAMEWORK_PATH/Python.framework/Versions/2.6/bin/"* "$INSTALL/bin"
    # echo "Remember to edit disable_linecache to add third parameter."
fi

exit 0