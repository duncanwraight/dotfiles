#!/bin/bash

crepo () {
    # Requires $REPOS_PATH and $COL_SCRIPT_PATH environment variables
    source $COL_SCRIPT_PATH
    REPOS_STORAGE_FILE=${REPOS_PATH}/repo-aliases

    if [ $# -eq 0 ]; then
        echo -e "\n${COL_LBLUE}Stored repositories:${COL_BLANK}\n"
        cat $REPOS_STORAGE_FILE
        echo -e "\n${COL_LBLUE}Available directories:${COL_BLANK}\n"
        tree -L 1 -d ${REPOS_PATH}
    else
        case "$1" in
            add )
                if [[ -n $2 ]] && [[ -n $3 ]]; then
                    if [[ $3 == *"/"* ]]; then
                        echo -e "${2}:${3}" >> $REPOS_STORAGE_FILE
                        echo -e "\nNew repository added: ${COL_LBLUE}\"${2}\" with path \"${3}\""
                    else
                        echo -e "\n${COL_RED}Invalid path${COL_BLANK}"
                        echo "Format: (reponame) [${REPOS_PATH}]/(path/to/repo)"
                        echo "  e.g. crepo add aws platform/harambe-aws-ci"
                        echo "       would add ${REPOS_PATH}/platform/harambe-aws-ci to \"crepo aws\""
                    fi
                else
                    echo -e "\n${COL_RED}Missing parameters${COL_BLANK}"
                    echo "Format: (reponame) [${REPOS_PATH}]/(path/to/repo)"
                    echo "  e.g. crepo add aws platform/harambe-aws-ci"
                    echo "       would add ${REPOS_PATH}/platform/harambe-aws-ci to \"crepo aws\""
                fi
                ;;
            * )
                FOUND=0
                while read -r line;
                do
                    if [[ $line =~ ^$1:.* ]]; then
                        DIR=`cut -d ":" -f 2 <<< "$line"`
                        FOUND=1
                        if [[ $DIR != "/"* ]]; then
                            DIR=${REPOS_PATH}/$DIR
                            BASE=`basename $DIR`
                            ENV=~/Envs/Python/3/$BASE
                        fi
                        if [ -d "$DIR" ]; then
                            cd $DIR
                            echo -e "Navigating to: $(dirname "${DIR}")/${COL_LBLUE}$(basename "${DIR}")${COL_BLANK}"
                            if [ -d "$ENV" ]; then
                                echo -e "Activating correlating Python environment: ${DIR}"
                                source $ENV/bin/activate
                            else
                                deactivate >/dev/null 2>&1
                            fi
                        else
                            echo "Directory ${DIR} does not exist"
                        fi
                    fi
                done < "$REPOS_STORAGE_FILE"

                if [ "$FOUND" -ne 1 ]; then
                    echo -e "\nUnable to find repo \"${1}\"\n"

                    cat $REPOS_STORAGE_FILE
                fi
                ;;
        esac
    fi
}
