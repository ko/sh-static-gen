#!/bin/bash

. config

if [ "$1z" = "cleanz" ]; then
    rm -rf $BUILD_DIR
    ls
    exit
fi

if [ ! -d $BUILD_DIR ]; then
    mkdir $BUILD_DIR
fi
cd $BUILD_DIR

python2.7 $THIRD_PARTY_DIR/markdown2.py "$POST_DIR/0001. intruded.net_narnia_level_3.html" > 001.narnia


