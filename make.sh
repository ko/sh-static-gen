#!/bin/bash

. config

POST_LIST=""


declare -i NONCE=$RANDOM

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

post_html_normalize()
{
    P_DST_BUILD=$1
    # setup the html for <pre> on $$\code
    P_CODE_START="\$\$code(.*)"
    P_CODE_END="\$\$/code"
    sed -i "s,$P_CODE_START,<pre>,g" $P_DST_BUILD
    sed -i "s,$P_CODE_END,</pre>,g" $P_DST_BUILD
}

create_post_list()
{
    #   Create list of linked posts
    #
    for p in `ls -1 $POST_DIR/`
    do
        # get metadata from post
        # TODO read once, parse in memory
        P_SRC=$POST_DIR/$p
        P_PERMALINK=`grep -m1 "^permalink:" $P_SRC | cut -d' ' -f2`
        P_TITLE=`grep -m1 "^title:" $P_SRC | cut -d' ' -f2-`
        P_DATE=`grep -m1 "^date:" $P_SRC | cut -d' ' -f2-`

        # setup the html for <a>
        P_DST_LIVE="/p/$P_PERMALINK.html"
        P_DST_BUILD="$BUILD_DIR/$P_DST_LIVE"
        P_A="<a href=\"$P_DST_LIVE\">$P_TITLE</a>"

        # add the date to the right of <a> in a table
        P_A="<td>$P_A</td><td>$P_DATE</td>"

        # create the link list
        POST_LIST="$P_A</tr>$POST_LIST"
        $PYTHON_BIN $THIRD_PARTY_DIR/markdown2.py "$POST_DIR/$p" > $P_DST_BUILD

        post_html_normalize $P_DST_BUILD

    done

    POST_LIST="<table><tr>$POST_LIST</table><br>"
}

# Description:  Replace whatever you can with the proper HTML 
#               &entity_name as found in the w3schools site:
#
#               http://www.w3schools.com/html/html_entities.asp
#
#               Also, get rid of any commas and temporarily replace
#               them in the HTML that we want to drop in later
#               during the populate_template() phase. We'll add them
#               back with the escape_post() function within the
#               populate_template() function.
#
escape_pre()
{
    local TXT=$1

    # Do this first or else... lol
    TXT=`echo $TXT | sed -e 's,\&,\&amp;,g'`

    # TODO need to be smarter about this. 
    #
    # < and >
    #TXT=`echo $TXT | sed -e 's,<,\&lt;,g'`
    #TXT=`echo $TXT | sed -e 's,>,\&gt;,g 

    TXT=`echo $TXT | sed -e "s/,/${NONCE}DELIMITER${NONCE}/g"`

    echo $TXT
}

# Description:  Add the commas (,) back to the file that we removed 
#               earlier in escape_pre().

escape_post()
{ 
    local TXT=$1

    TXT=`echo $TXT | sed -e "s/${NONCE}DELIMITER${NONCE}/,/g"`

    echo $TXT
}

# Description:  Escape everything. Add it to the proper
#               place in the file based off the template
#               keywords and do final preparation regarding
#               the delimiter.
#
populate_template()
{
    AUTHOR=$(escape_pre "$AUTHOR")
    LOG $DEBUG "==== AUTHOR ===="
    LOG $DEBUG "$AUTHOR"
    TITLE=$(escape_pre "$TITLE")
    LOG $DEBUG "==== TITLE ===="
    LOG $DEBUG "$TITLE"
    POST_LIST=$(escape_pre "$POST_LIST")
    LOG $DEBUG "=== POST LIST ===="
    LOG $DEBUG "$POST_LIST"

    #   Replace all the variables in the "templates"
    #
    for FILE in `ls -1 $BUILD_DIR`; do
        if [ -f $FILE ]; then
            # TODO fix this broken sed 
            LOG $DEBUG "===== $FILE ====="
            sed -i "s,{{ AUTHOR }},$AUTHOR,g" $BUILD_DIR/$FILE
            sed -i "s,{{ TITLE }},$TITLE,g" $BUILD_DIR/$FILE
            sed -i "s,{{ POST_LIST }},$POST_LIST,g" $BUILD_DIR/$FILE
            PREPARED_FILE=$(escape_post "`cat $BUILD_DIR/$FILE`")
            echo >$BUILD_DIR/$FILE $PREPARED_FILE
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
