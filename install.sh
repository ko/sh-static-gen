#!/bin/bash

. config

rm -rf $LIVE_DIR/*
cp -R $BUILD_DIR/* $LIVE_DIR/
touch $LIVE_DIR/p/index.html
