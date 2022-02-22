export JSONPATH_NAME='{.items[*].metadata.name}'
export JSONPATH_IMAGE='{$.spec.template.spec.containers[:1].image}'

kubectx() {
    source $COL_SCRIPT_PATH;

    if [[ "$#" -ne "1" ]] || [[ "$1" != "staging" && "$1" != "demo" && "$1" != "production" ]] ; then
        echo "kubectx requires 1 parameter - staging, demo, production"
        return
    fi

    # Run oaws command to ensure importio Okta profile and default AWS profile are in use
    echo "${COL_LBLUE}Checking AWS credentials/configuration...${COL_BLANK}"
    oaws

    if [ $? -ne 0 ]; then
        echo "${COL_RED} Okta AWS authentication failed. Exiting..."
        return
    fi

    ENV=$1
    echo "${COL_LBLUE}Getting credentials for ${COL_GRN}${(C)ENV}${COL_BLANK} cluster${COL_BLANK}"
    aws eks update-kubeconfig --region "us-east-1" --name "k8s-${ENV}" --role-arn arn:aws:iam::448216300011:role/k8s-master-user-role

    echo "${COL_LBLUE}Setting default NS to ${COL_GRN}'chromium-server'${COL_BLANK}"
    kubectl config set-context --current --namespace=chromium-server
}
