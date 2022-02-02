#!/bin/bash

sshkeys() {
    source $COL_SCRIPT_PATH > /dev/null 2>&1

    echo -e "${COL_LBLUE}Removing existing keys...${COL_BLANK}"
    ssh-add -D

    if [ "$#" -ne 1 ]; then
        echo -e "${COL_RED}Error: sshkeys command accepts only 1 argument${COL_BLANK}"
        return 1
    fi

    FOLDER=$1

    if [ ! -d ~/.ssh/${FOLDER} ]; then
        echo -e "${COL_RED}Error: Folder ${FOLDER} does not exist in ~/.ssh${COL_BLANK}"
        return 1
    else
        echo -e "${COL_LBLUE}Adding ${COL_RED}${FOLDER}${COL_LBLUE} SSH key(s)${COL_BLANK}"
        for key in $(find ~/.ssh/$FOLDER -type f -follow -not -name "*.pub" -not -name "config" -not -name "known_hosts*") ; do
            echo "... ${COL_LBLUE}${key}${COL_BLANK}"
            ssh-add $key > /dev/null 2>&1
        done
    fi
}