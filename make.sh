#!/bin/bash

. config

POST_LIST=""

workspace_prep()
{
    #   prep the src dir
    #
    rename ' ' '_' $POST_DIR/*

    #   prep and setup the build dir
    #
    if [ ! -d $BUILD_DIR ]; then
        mkdir $BUILD_DIR
    fi
    cd $BUILD_DIR
    cp -R $SRC_DIR/* $BUILD_DIR/
}



create_post_list()
{
    #   Create list of linked posts
    #
    for p in `ls -1 $POST_DIR/`
    do
        POST_LIST="$p<br>\n\t$POST_LIST"
        $PYTHON_BIN $THIRD_PARTY_DIR/markdown2.py $POST_DIR/$p > $p
    done
}

populate_template()
{
    #   Replace all the variables in the "templates"
    #
    sed -i "s,{{ AUTHOR }},$AUTHOR,g" $BUILD_DIR/*
    sed -i "s,{{ TITLE }},$TITLE,g" $BUILD_DIR/*
    sed -i "s,{{ POST_LIST }},$POST_LIST,g" $BUILD_DIR/*
}


#   handle the 'make clean' case
#
if [ "$1z" = "cleanz" ]; then
    rm -rf $BUILD_DIR
    ls
    exit
fi


workspace_prep
create_post_list
populate_template
