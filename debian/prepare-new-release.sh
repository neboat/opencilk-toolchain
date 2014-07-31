#!/bin/sh
ORIG_VERSION=3.5
TARGET_VERSION=3.6
ORIG_VERSION_2=3_5
TARGET_VERSION_2=3_6

LIST=`ls debian/control debian/orig-tar.sh debian/rules`
for F in $LIST; do
    sed -i -e "s|$ORIG_VERSION_2|$TARGET_VERSION_2|g" $F
    sed -i -e "s|$ORIG_VERSION|$TARGET_VERSION|g" $F
done

