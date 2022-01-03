#!/bin/bash

#source $COL_SCRIPT_PATH

trap ctrl_c INT

vpn() {
    CONNECTION_NAME=QuadPay_duncan.wraight@quadpay.com_primary
    CONNECTION_STATE=$(nmcli -f GENERAL.STATE con show ${CONNECTION_NAME})

    if [[ "$1" == "status" ]]; then
        if [ $CONNECTION_STATE ]; then
            echo -e "${COL_GRN}You are currently connected to the VPN${COL_BLANK}"
        else
            echo -e "${COL_RED}You are NOT currently connected to the VPN${COL_BLANK}"
        fi

        return
    fi

    if [ $CONNECTION_STATE ]; then
        echo -e "${COL_GRN}You are currently connected to the VPN${COL_BLANK}"
        echo -e "${COL_LBLU}Disconnecting...${COL_BLANK}"
        nmcli connection down $CONNECTION_NAME

        if [ $? -eq 0 ]; then
            echo -e "${COL_GRN}Disconnected${COL_BLANK}"
        else
            echo "${COL_RED}Something went wrong, error code: ${?}${COL_BLANK}"
        fi
    else
        echo "${COL_GRN}Connecting to VPN...${COL_BLANK}"
        nmcli connection up $CONNECTION_NAME --ask

        if [ $? -eq 0 ]; then
            echo -e "${COL_GRN}Connected${COL_BLANK}"
        else
            echo "${COL_RED}Something went wrong, error code: ${?}${COL_BLANK}"
        fi
    fi
}

function ctrl_c() {
    echo "** Trapped CTRL-C"
    echo -e "${COL_RED}Not connected${COL_BLANK}"
}
