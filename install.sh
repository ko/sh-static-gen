#!/bin/bash


BUILD_DIR=build/
LIVE_DIR=~/webapps/yaksok_static/

rm -rf $LIVE_DIR/*
cp -R $BUILD_DIR/* $LIVE_DIR/
