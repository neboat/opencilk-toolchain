#!/bin/sh
ORIG_VERSION=4.0
TARGET_VERSION=5.0
ORIG_VERSION_2=4_0
TARGET_VERSION_2=5_0

LIST=`ls debian/control debian/orig-tar.sh debian/rules debian/patches/clang-analyzer-force-version.diff debian/patches/clang-format-version.diff debian/patches/python-clangpath.diff debian/patches/scan-build-clang-path.diff debian/patches/lldb-libname.diff debian/patches/fix-scan-view-path.diff debian/patches/lldb-addversion-suffix-to-llvm-server-exec.patch debian/patches/clang-tidy-run-bin.diff`
for F in $LIST; do
    sed -i -e "s|$ORIG_VERSION_2|$TARGET_VERSION_2|g" $F
    sed -i -e "s|$ORIG_VERSION|$TARGET_VERSION|g" $F
done

