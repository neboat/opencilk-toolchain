#!/bin/sh
# This script will create the following tarballs:
# llvm-toolchain-snapshot-3.2_3.2repack.orig-clang.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-clang-extra.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-compiler-rt.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-lld.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-lldb.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-polly.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-openmp.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-libcxx.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig-libcxxabi.tar.bz2
# llvm-toolchain-snapshot-3.2_3.2repack.orig.tar.bz2

set -e

# commands:
#  sh -v 8/debian/orig-tar.sh release/8.x
#  sh -v 8/debian/orig-tar.sh 8.0.0 rc3
#  sh -v 8/debian/orig-tar.sh 8.0.1 rc3


# To create an rc1 release:
# sh 4.0/debian/orig-tar.sh RELEASE_40 rc1

GIT_BASE_URL=https://github.com/llvm/llvm-project

PATH_DEBIAN="$(pwd)/$(dirname $0)/../"
cd $PATH_DEBIAN
MAJOR_VERSION=$(dpkg-parsechangelog | sed -rne "s,^Version: 1:([0-9]+).*,\1,p")
if test -z "$MAJOR_VERSION"; then
    echo "Could not detect the major version"
    exit 1
fi
CURRENT_VERSION=$(dpkg-parsechangelog | sed -rne "s,^Version: 1:([0-9.]+)(~|-)(.*),\1,p")
if test -z "$CURRENT_VERSION"; then
    echo "Could not detect the full version"
    exit 1
fi
echo $MAJOR_VERSION
echo $CURRENT_VERSION
cd -


if test -n "$1"; then
# https://llvm.org/svn/llvm-project/{cfe,llvm,compiler-rt,...}/branches/google/stable/
# For example: sh 4.0/debian/orig-tar.sh release_400
    BRANCH=$1
else
    cd $PATH_DEBIAN
    SOURCE=$(dpkg-parsechangelog |grep ^Source|awk '{print $2}')
    cd -
    if test $SOURCE != "llvm-toolchain-snapshot"; then
       echo "Checkout of the master is only available for llvm-toolchain-snapshot"
       exit 1
    fi
    BRANCH="master"
fi

if test -n "$1" -a -n "$2"; then
# https://llvm.org/svn/llvm-project/{cfe,llvm,compiler-rt,...}/tags/RELEASE_34/rc1/
# For example: sh 4.0/debian/orig-tar.sh RELEASE_401 rc3 4.0.1
    TAG=$2
    RCRELEASE="true"
    if test -z "$3"; then
        echo "Please provide the exact version. Used for the tarball name  Ex: 4.0.1"
    fi
    EXACT_VERSION=$1
fi

# Update or retrieve the repo
mkdir -p git-archive
cd git-archive
if test -d llvm-project; then
    # Update it
    cd llvm-project
    git remote update
    git reset --hard origin/master
    git clean -qfd
    git checkout master
    cd ..
else
    # Download it
    git clone $GIT_BASE_URL
fi

cd llvm-project
if test -z  "$TAG"; then
    # Building a branch
    git checkout $BRANCH
    if test $BRANCH != "master"; then
        VERSION=$(echo $BRANCH|cut -d/ -f2|cut -d. -f1)
        if ! echo $MAJOR_VERSION|grep -q $VERSION; then
            echo "mismatch in version: Dir=$MAJOR_VERSION Provided=$VERSION"
            exit 1
        fi
    else
        # No argument, take master. So, it can only be snapshot
        VERSION=$MAJOR_VERSION
        MAJOR_VERSION=snapshot
    fi
    # the + is here to make sure that this version is considered more recent than the svn
    # dpkg --compare-versions 10~svn374977-1~exp1 lt 10~+2019-svn374977-1~exp1
    # to verify that
    VERSION="${VERSION}~+$(git log -1 --pretty=format:'%ci-%h'|sed -e "s|+\(.*\)-|+|g" -e "s| ||g" -e "s|-||g" -e "s|:||g" )"
else

    if ! echo $EXACT_VERSION|grep -q $MAJOR_VERSION; then
        echo "Mismatch in version: Dir=$MAJOR_VERSION Provided=$EXACT_VERSION"
        exit 1
    fi
    git_tag="llvmorg-$EXACT_VERSION"
    VERSION=$EXACT_VERSION

    if test -n "$TAG"; then
        git_tag="$git_tag-$TAG"
        VERSION="$VERSION~+$TAG"
    fi
    echo $git_tag
    git checkout $git_tag > /dev/null

fi

# cleanup
rm -rf */www/

cd -
BASE="llvm-toolchain-${MAJOR_VERSION}_${VERSION}"
FILENAME="${BASE}.orig.tar.xz"
echo "Compressing to $FILENAME"
tar Jcf $FILENAME --exclude .git --transform="s/llvm-project/$BASE/" llvm-project

export DEBFULLNAME="Sylvestre Ledru"
export DEBEMAIL="sylvestre@debian.org"
cd $PATH_DEBIAN

if test -z "$DISTRIBUTION"; then
    DISTRIBUTION="experimental"
fi

if test -n "$RCRELEASE" -o -n "$BRANCH"; then
    EXTRA_DCH_FLAGS="--force-bad-version --allow-lower-version"
fi

dch $EXTRA_DCH_FLAGS --distribution $DISTRIBUTION --newversion 1:$VERSION-1~exp1 "New snapshot release"

exit 0
