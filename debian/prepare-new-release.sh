#!/bin/sh
ORIG_VERSION=13
TARGET_VERSION=14
ORIG_VERSION_2=13_0
TARGET_VERSION_2=14_0
ORIG_VERSION_3=130
TARGET_VERSION_3=140

LIST=`ls debian/control debian/orig-tar.sh debian/rules debian/patches/clang-analyzer-force-version.diff debian/patches/clang-format-version.diff debian/patches/python-clangpath.diff debian/patches/scan-build-clang-path.diff debian/patches/lldb-libname.diff debian/patches/fix-scan-view-path.diff debian/patches/lldb/lldb-addversion-suffix-to-llvm-server-exec.patch debian/patches/clang-tidy-run-bin.diff debian/patches/fix-scan-view-path.diff debian/README debian/patches/clang-analyzer-force-version.diff debian/patches/clang-tidy-run-bin.diff debian/tests/control debian/tests/integration-test-suite-test debian/unpack.sh debian/tests/cmake-test debian/patches/scan-build-py-fix-analyze-path.diff debian/patches/scan-build-py-fix-default-bin.diff`
for F in $LIST; do
    sed -i -e "s|$ORIG_VERSION_3|$TARGET_VERSION_3|g" $F
    sed -i -e "s|$ORIG_VERSION_2|$TARGET_VERSION_2|g" $F
    sed -i -e "s|$ORIG_VERSION|$TARGET_VERSION|g" $F
done

echo "once you copy the old version into a new branch"
echo "edit debian/rules, maybe update SONAME_CLANG"
echo "edit debian/control, update the VCS links"
echo "edit debian/control, update the source pkg name"
echo "edit debian/changelog, update the source pkg name"
