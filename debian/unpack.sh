set -e

MAJOR_VERSION=`ls -1 *svn*bz2 | tail -1|perl -ne 'print "$1\n" if /(\d+)~svn/;' | sort -ru`
SVN_REV=`ls -1 *svn*bz2 | tail -1|perl -ne 'print "$1\n" if /svn(\d+)/;' | sort -ru`
echo "Unpack of llvm"
tar jxf llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig.tar.bz2
cd llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV/ || ( echo "Bad SVN_REV:\"$SVN_REV\"" && exit 1 )
for f in ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-clang.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-clang-tools-extra.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-compiler-rt.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-lld.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-lldb.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-polly.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-openmp.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-libcxx.tar.bz2 ../llvm-toolchain-snapshot_$MAJOR_VERSION~svn$SVN_REV.orig-libcxxabi.tar.bz2; do
	if test -e $f; then
		echo "unpack of $f"
		tar jxf $f
	fi
 done
ln -s clang_$MAJOR_VERSION~svn$SVN_REV clang
ln -s clang-tools-extra_$MAJOR_VERSION~svn$SVN_REV clang-tools-extra
ln -s compiler-rt_$MAJOR_VERSION~svn$SVN_REV compiler-rt
ln -s polly_$MAJOR_VERSION~svn$SVN_REV polly
ln -s lld_$MAJOR_VERSION~svn$SVN_REV lld
ln -s lldb_$MAJOR_VERSION~svn$SVN_REV lldb
ln -s openmp_$MAJOR_VERSION~svn$SVN_REV openmp
ln -s libcxx_$MAJOR_VERSION~svn$SVN_REV libcxx
ln -s libcxxabi_$MAJOR_VERSION~svn$SVN_REV libcxxabi
cp -R ../snapshot/debian .
QUILT_PATCHES=debian/patches/ quilt push -a --fuzz=0
