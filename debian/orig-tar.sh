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
LLVM_TARGET=llvm-toolchain_3.3~svn$REVISION
$SVN_CMD/llvm/trunk $LLVM_TARGET
tar jcvf llvm-toolchain_3.3~svn$REVISION.orig.tar.bz2 $LLVM_TARGET
rm -rf $LLVM_TARGET

# Clang
CLANG_TARGET=clang_3.3~svn$REVISION
$SVN_CMD/cfe/trunk $CLANG_TARGET
tar jcvf llvm-toolchain_3.3~svn$REVISION.orig-clang.tar.bz2 $CLANG_TARGET
rm -rf $CLANG_TARGET

# Compiler-rt
COMPILER_RT_TARGET=compiler-rt_3.3~svn$REVISION
$SVN_CMD/compiler-rt/trunk $COMPILER_RT_TARGET
tar jcvf llvm-toolchain_3.3~svn$REVISION.orig-compiler-rt.tar.bz2 $COMPILER_RT_TARGET
rm -rf $COMPILER_RT_TARGET

# Polly
POLLY_TARGET=polly_3.3~svn$REVISION
$SVN_CMD/polly/trunk $POLLY_TARGET
tar jcvf llvm-toolchain_3.3~svn$REVISION.orig-polly.tar.bz2 $POLLY_TARGET
rm -rf $POLLY_TARGET

# LLDB
LLDB_TARGET=lldb_3.3~svn$REVISION
$SVN_CMD/lldb/trunk $LLDB_TARGET
tar jcvf llvm-toolchain_3.3~svn$REVISION.orig-lldb.tar.bz2 $LLDB_TARGET
rm -rf $LLDB_TARGET


exit 0

