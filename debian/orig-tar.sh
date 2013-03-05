#!/bin/sh
# This script will create the following tarballs:
# llvm-toolchain-3.2_3.2repack.orig-clang.tar.bz2
# llvm-toolchain-3.2_3.2repack.orig-compiler-rt.tar.bz2
# llvm-toolchain-3.2_3.2repack.orig-lldb.tar.bz2
# llvm-toolchain-3.2_3.2repack.orig-polly.tar.bz2
# llvm-toolchain-3.2_3.2repack.orig.tar.bz2

SVN_URL=http://llvm.org/svn/llvm-project/
REVISION=$(LANG=C svn info $SVN_URL|grep "^Revision:"|awk '{print $2}')
SVN_CMD="svn export -r $REVISION $SVN_URL"
MAJOR_VERSION=3.3

# LLVM
LLVM_TARGET=llvm-toolchain_$MAJOR_VERSION~svn$REVISION
$SVN_CMD/llvm/trunk $LLVM_TARGET
tar jcvf llvm-toolchain_$MAJOR_VERSION~svn$REVISION.orig.tar.bz2 $LLVM_TARGET
rm -rf $LLVM_TARGET

# Clang
CLANG_TARGET=clang_$MAJOR_VERSION~svn$REVISION
$SVN_CMD/cfe/trunk $CLANG_TARGET
tar jcvf llvm-toolchain_$MAJOR_VERSION~svn$REVISION.orig-clang.tar.bz2 $CLANG_TARGET
rm -rf $CLANG_TARGET

# Compiler-rt
COMPILER_RT_TARGET=compiler-rt_$MAJOR_VERSION~svn$REVISION
$SVN_CMD/compiler-rt/trunk $COMPILER_RT_TARGET
tar jcvf llvm-toolchain_$MAJOR_VERSION~svn$REVISION.orig-compiler-rt.tar.bz2 $COMPILER_RT_TARGET
rm -rf $COMPILER_RT_TARGET

# Polly
POLLY_TARGET=polly_$MAJOR_VERSION~svn$REVISION
$SVN_CMD/polly/trunk $POLLY_TARGET
tar jcvf llvm-toolchain_$MAJOR_VERSION~svn$REVISION.orig-polly.tar.bz2 $POLLY_TARGET
rm -rf $POLLY_TARGET

# LLDB
LLDB_TARGET=lldb_$MAJOR_VERSION~svn$REVISION
$SVN_CMD/lldb/trunk $LLDB_TARGET
tar jcvf llvm-toolchain_$MAJOR_VERSION~svn$REVISION.orig-lldb.tar.bz2 $LLDB_TARGET
rm -rf $LLDB_TARGET

PATH_DEBIAN="$(pwd)/$(dirname $0)/../"
echo "going into $PATH_DEBIAN"
export DEBFULLNAME="Sylvestre Ledru"
export DEBEMAIL="sylvestre@debian.org"
cd $PATH_DEBIAN
dch --distribution experimental --newversion 1:$MAJOR_VERSION~svn$REVISION-1~exp1 "New snapshot release"

exit 0
