#!/bin/bash

azgetregion() {
    source $COL_SCRIPT_PATH

    # Regions and Azure codes
    if [[ "$1" == "uk" ]]; then
        REGION_FULL="United Kingdom"
        REGION_AZURE="uksouth"
    elif [[ "$1" == "uae" ]]; then
        REGION_FULL="United Arab Emirates"
        REGION_AZURE="uaenorth"
    elif [[ "$1" == "mx" ]]; then
        REGION_FULL="Mexico"
        REGION_AZURE="southcus"
    elif [[ "$1" == "ca" ]]; then
        REGION_FULL="Canada"
        REGION_AZURE="canadacentral"
    elif [[ "$1" == "sg" ]]; then
        REGION_FULL="Singapore"
        REGION_AZURE="southeastasia"
    elif [[ "$1" == "us" ]]; then
        REGION_FULL="United States"
        REGION_AZURE="eastus"
    else
        echo -e "${COL_RED}ERROR: ${COL_BLANK}Region not found"
        return
    fi
}
    
qpgetenv() {
    source $COL_SCRIPT_PATH

    # Environments and associated namespaces
    if [[ "$1" == "dev" ]]; then
        ENVIRONMENT="Development"
        NAMESPACE="master"
    elif [[ "$1" == "sbx" ]]; then
        ENVIRONMENT="Sandbox"
        NAMESPACE="sandbox"
    elif [[ "$1" == "prd" ]]; then
        ENVIRONMENT="Production"
        NAMESPACE="api"
    else
        echo -e "${COL_RED}ERROR: ${COL_BLANK}Environment not found"
        return
    fi
}

azsetsubscription() {
    source $COL_SCRIPT_PATH

    azgetregion $1
    qpgetenv $2

    if [[ "$REGION_FULL" == "United States" ]]; then
        SUBSCRIPTION="QuadPay PAYG"
        RG="qp-${2}-cluster"
    else
        SUBSCRIPTION="${REGION_FULL} - ${ENVIRONMENT}"
        RG="qp-${REGION_AZURE}-${2}-cluster"
    fi
    
    CLUSTER="quadpay-${REGION_AZURE}-${2}-cluster"

    az account set --subscription "${SUBSCRIPTION}"
    if [ $? -ne 0 ]; then
        echo -e "${COL_RED}ERROR: You need to log in to Azure...${COL_BLANK}"
        echo -e "${COL_LBLUE}Do this, then re-run the command${COL_BLANK}"
        az login
        return
    fi
}

aks() {
    source $COL_SCRIPT_PATH

    azsetsubscription $1 $2

    echo -e "${COL_LBLUE}Switching kubectl context to ${COL_GRN}${REGION_FULL} - ${ENVIRONMENT}${COL_BLANK}"
    az aks get-credentials -g ${RG} -n ${CLUSTER} --subscription "${SUBSCRIPTION}" --admin --overwrite-existing --only-show-errors > /dev/null
    kubectl config use-context ${CLUSTER}-admin > /dev/null
    kubectl config set-context --current --namespace=${NAMESPACE} > /dev/null
}

cdndeploy() {
    source $COL_SCRIPT_PATH

    azsetsubscription $1 $2

    PROJECT=$3
    REPO_PATH="~/Repos/Quadpay/quadpay-${PROJECT}"
    CDN_STORAGE_ACCOUNT="${1}qp${ENVIRONMENT:l}cdn"
    CDN_RESOURCE_GROUP="${1}-quadpay-${ENVIRONMENT:l}-cdn"
    CDN_NAME="${1}-quadpay-${ENVIRONMENT:l}-${PROJECT}"

    AVAILABLE_PROJECTS=("customer-portal", "merchant-portal", "virtual-checkout", "checkout")
    
    if [ -z $PROJECT ] || [[ ! "${AVAILABLE_PROJECTS[@]}" =~ "${PROJECT}" ]]; then
        echo -e "${COL_RED}ERROR: ${PROJECT} is not a valid CDN project. Exiting${COL_BLANK}"
        return
    fi

    echo -e "${COL_LBLUE}Deploying ${COL_GRN}${3}${COL_BLANK} from ${COL_GRN}${REPO_PATH}${COL_BLANK} to ${COL_GRN}${CDN_STORAGE_ACCOUNT}${COL_BLANK} / ${COL_GRN}${CDN_NAME}${COL_BLANK}"

    echo "Are you sure you want to continue? (Y/n)"
    read CONFIRMATION

    if [[ "${CONFIRMATION}" != "y" ]]; then
        echo -e "${COL_RED}ERROR: Confirmation is required. Exiting${COL_BLANK}"
        return
    fi

    echo "Deleting all files from storage account"
    az storage blob delete-batch --source $3 --account-name $CDN_STORAGE_ACC --pattern '*'

    echo "Uploading newly-built files"
    az storage blob upload-batch --destination $3 --account-name $CDN_STORAGE_ACC --source $REPO_PATH/dist-development-$1

    if [[ "$3" == "customer-portal" ]]; then
        echo "Uploading direction.html file"
        az storage blob upload -f $REPO_PATH/direction.html --account-name $CDN_STORAGE_ACC -c customer-portal -n direction.html
    fi

    echo "Purging CDN"
    az cdn endpoint purge -g $CDN_RESOURCE_GROUP -n $CDN_NAME --profile-name $CDN_NAME --content-paths '/*'

    echo -e "${COL_GRN}CDN deployment complete${COL_BLANK}"
}

azsecretssincedate() {
    # This doesn't currently work... it's just here for reference
    DATE=`date -d '$1 00:00:00' +%S` az keyvault secret list --vault-name qp-uksouth-dev-kv | jq --arg DATE "$DATE" '.[] | select (.attributes.updated | (split("+")[0] + "Z") | fromdateiso8601 > $DATE) | .name'
}
