#!/bin/bash

sshkeys () {
    source $COL_SCRIPT_PATH

    echo -e "${COL_LBLUE}Removing existing keys...${COL_BLANK}"
    ssh-add -D

    if [[ "$1" == "qp" ]] || [[ "$1" == "zip" ]]; then
        echo -e "${COL_LBLUE}Adding ${COL_RED}Zip/QuadPay${COL_LBLUE} SSH key${COL_BLANK}"
        ssh-add $HOME/.ssh/zip/qp_id_ed25519 > /dev/null 2>&1
    elif [[ "$1" == "import" ]]; then
        echo -e "${COL_LBLUE}Adding ${COL_RED}import.io${COL_LBLUE} SSH key${COL_BLANK}"
        ssh-add $HOME/.ssh/import/import_id_ed25519 > /dev/null 2>&1
    else
        echo -e "${COL_LBLUE}Adding ${COL_RED}personal${COL_LBLUE} SSH key${COL_BLANK}"
        ssh-add $HOME/.ssh/personal/pers_id_ed25519 > /dev/null 2>&1
    fi
}
