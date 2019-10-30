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
#  sh 9/debian/orig-tar.sh release/9.x
#  sh 9/debian/orig-tar.sh 9.0.0 rc3
#  sh 9/debian/orig-tar.sh 9.0.1 rc3
# Stable release
#  sh 9/debian/orig-tar.sh 9.0.0 9.0.0


# To create an rc1 release:
# sh 4.0/debian/orig-tar.sh release/9.x

GIT_BASE_URL=https://github.com/llvm/llvm-project

PATH_DEBIAN="$(pwd)/$(dirname $0)/../"
cd "$PATH_DEBIAN"
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
cd -


if test -n "$1"; then
# https://github.com/llvm/llvm-project/tree/release/9.x
# For example: sh 4.0/debian/orig-tar.sh release/9.x
    BRANCH=$1
    if ! echo "$1"|grep release/; then
        # The first argument is NOT a branch, means that it is a stable release
        FINAL_RELEASE=true
        EXACT_VERSION=$1
    fi
else
    # No argument, we need trunk
    cd "$PATH_DEBIAN"
    SOURCE=$(dpkg-parsechangelog |grep ^Source|awk '{print $2}')
    cd -
    if test "$SOURCE" != "llvm-toolchain-snapshot"; then
       echo "Checkout of the master is only available for llvm-toolchain-snapshot"
       exit 1
    fi
    BRANCH="master"
fi

if test -n "$1" -a -n "$2"; then
# https://github.com/llvm/llvm-project/releases/tag/llvmorg-9.0.0
# For example: sh 4.0/debian/orig-tar.sh 4.0.1 rc3
# or  sh 9/debian/orig-tar.sh 9.0.0
    TAG=$2
    RCRELEASE="true"
    EXACT_VERSION=$1
fi

# Update or retrieve the repo
mkdir -p git-archive
cd git-archive
if test -d llvm-project; then
    # Update it
    cd llvm-project
    git remote update > /dev/null
    git reset --hard origin/master > /dev/null
    git clean -qfd
    git checkout master > /dev/null
    cd ..
else
    # Download it
    git clone $GIT_BASE_URL
fi

cd llvm-project
if test -z  "$TAG" -a -z "$FINAL_RELEASE"; then
    # Building a branch
    git checkout $BRANCH
    git pull
    if test $BRANCH != "master"; then
        VERSION=$(echo $BRANCH|cut -d/ -f2|cut -d. -f1)
        if ! echo "$MAJOR_VERSION"|grep -q "$VERSION"; then
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

    if ! echo "$EXACT_VERSION"|grep -q "$MAJOR_VERSION"; then
        echo "Mismatch in version: Dir=$MAJOR_VERSION Provided=$EXACT_VERSION"
        exit 1
    fi
    git_tag="llvmorg-$EXACT_VERSION"
    VERSION=$EXACT_VERSION
    if test -n "$TAG" -a -z "$FINAL_RELEASE"; then
        git_tag="$git_tag-$TAG"
        VERSION="$VERSION~+$TAG"
    fi

    git checkout "$git_tag" > /dev/null
    git pull

fi

# cleanup
rm -rf */www/

cd ../
BASE="llvm-toolchain-${MAJOR_VERSION}_${VERSION}"
FILENAME="${BASE}.orig.tar.xz"
echo "Compressing to $FILENAME"
tar Jcf ../"$FILENAME" --exclude .git --transform="s/llvm-project/$BASE/" llvm-project

export DEBFULLNAME="Sylvestre Ledru"
export DEBEMAIL="sylvestre@debian.org"
cd "$PATH_DEBIAN"

if test -z "$DISTRIBUTION"; then
    DISTRIBUTION="experimental"
fi

if test -n "$RCRELEASE" -o -n "$BRANCH"; then
    EXTRA_DCH_FLAGS="--force-bad-version --allow-lower-version"
fi

dch $EXTRA_DCH_FLAGS --distribution $DISTRIBUTION --newversion 1:"$VERSION"-1~exp1 "New snapshot release"

exit 0
