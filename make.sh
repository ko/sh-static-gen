#!/bin/bash

. config

POST_LIST=""

declare -i LOGLEVEL=4
declare -i ERR=1
declare -i WARN=2
declare -i INFO=3
declare -i DEBUG=4
LOG()
{
    local MSGLEVEL=$1
    local MSG=$2
    if [ $MSGLEVEL -le $LOGLEVEL ]; then
        echo $MSG
    fi
}

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

    # where posts reside
    if [ ! -d $BUILD_DIR/p ]; then
        mkdir $BUILD_DIR/p
    fi
}

create_post_list()
{
    #   Create list of linked posts
    #
    for p in `ls -1 $POST_DIR/`
    do
        # get metadata from post
        # TODO read once, parse in memory
        P_PERMALINK=`grep -m1 "^permalink:" $POST_DIR/$p | cut -d' ' -f2`
        P_TITLE=`grep -m1 "^title:" $POST_DIR/$p | cut -d' ' -f2-`

        # setup the html for <a>
        P_DST_LIVE="/p/$P_PERMALINK"
        P_DST_BUILD="$BUILD_DIR/$P_DST_LIVE"
        P_A="<a href=\"$P_DST_LIVE\">$P_TITLE</a>"

        # create the link list
        POST_LIST="$P_A<br>$POST_LIST"
        $PYTHON_BIN $THIRD_PARTY_DIR/markdown2.py "$POST_DIR/$p" > $P_DST_BUILD
    done
}

escape_html()
{
    local TXT=$1

    # Do this first or else... lol
    TXT=`echo $TXT | sed -e 's,\&,\&amp;,g'`

    # < and >
    #TXT=`echo $TXT | sed -e 's,<,\&lt;,g'`
    #TXT=`echo $TXT | sed -e 's,>,\&gt;,g'`

    # rest are found @ http://www.w3schools.com/html/html_entities.asp

    echo $TXT
}

populate_template()
{
    AUTHOR=$(escape_html "$AUTHOR")
    LOG $DEBUG "==== AUTHOR ===="
    LOG $DEBUG "$AUTHOR"
    TITLE=$(escape_html "$TITLE")
    LOG $DEBUG "==== TITLE ===="
    LOG $DEBUG "$TITLE"
    POST_LIST=$(escape_html "$POST_LIST")
    LOG $DEBUG "=== POST LIST ===="
    LOG $DEBUG "$POST_LIST"

    #   Replace all the variables in the "templates"
    #
    for FILE in `ls -1 $BUILD_DIR`; do
        if [ -f $FILE ]; then
            # TODO fix this broken sed 
            LOG $DEBUG "===== $FILE ====="
            sed -i "s@{{ AUTHOR }}@$AUTHOR@g" $BUILD_DIR/$FILE
            sed -i "s@{{ TITLE }}@$TITLE@g" $BUILD_DIR/$FILE
            sed -i "s@{{ POST_LIST }}@$POST_LIST@g" $BUILD_DIR/$FILE
        fi
    done
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
