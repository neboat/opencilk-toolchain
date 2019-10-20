set -e
ORIG_VERSION=snapshot
MAJOR_VERSION=10 # 8.0.1
REV=`ls -1 *snapshot_$MAJOR_VERSION*~+*xz | tail -1|perl -ne 'print "$1\n" if /~\+(.*)\.orig/;'  | sort -ru`

#SVN_REV=347285
VERSION=$REV
echo $VERSION
#VERSION=+rc3
LLVM_ARCHIVE=llvm-toolchain-${ORIG_VERSION}_$MAJOR_VERSION~+$VERSION.orig.tar.xz
echo "unpack of $LLVM_ARCHIVE"
tar Jxf $LLVM_ARCHIVE
cd llvm-toolchain-${ORIG_VERSION}_$MAJOR_VERSION~+$VERSION/

cp -R ../snapshot/debian .
QUILT_PATCHES=debian/patches/ quilt push -a --fuzz=0
