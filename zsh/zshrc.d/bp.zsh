chgaws() {
    case "$1" in
        "lab")
            spoke="WS-01MG"
            environment="lab"
            ;;
        "dev")
            spoke="WS-01EE"
            environment="dev"
            ;;
        "sbx")
            spoke="WS-01D6"
            environment="sbx"
            ;;
        "prd")
            spoke="WS-01H5"
            environment="prd"
            ;;
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9])
            spoke="WS-01MG"
            environment="lab"
            ;;
        *)
            echo "usage: chgaws [lab|dev|sbx|prd|01234567]"
            return 1
            ;;
    esac

    export AWS_PROFILE="${spoke}-role_DEVOPS"
    echo "Checking for existing AWS authentication..."
    aws sts get-caller-identity > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Not authenticated; running awsconnect"
        awsconnect -b google-chrome
    else
        echo "Already authenticated"
    fi

    echo "Checking for EKS clusters..."
    clusters=("htf-${1}-eks-cluster" "htf-${1}-lab-eks-cluster")

    found_cluster=0

    for cluster in $clusters; do
        echo "Searching for cluster: ${cluster}"
        aws eks list-clusters | jq -e ".clusters | index(\"${cluster}\")" > /dev/null
        if [[ $? -ne 1 ]] ; then
            echo "Cluster found"
            found_cluster=1
            aws eks update-kubeconfig --region eu-west-1 --name "${cluster}" --profile $AWS_PROFILE
            return 0
        fi
    done

    if [[ "${found_cluster}" == 0 ]]; then
        echo "Unable to find a legitimate cluster with this environment/identifier combination"
        return 1
    fi
}

helmtest() {
    CURRENT_FOLDER=`realpath .`
    VERSION="0.1"
    PACKAGE_FOLDER="./helm/$1"
    OUTPUT_FILE="./${1}-${VERSION}.tgz"

    if [[ ! -d "$PACKAGE_FOLDER" ]]; then
        echo "Folder ${1} does not exist, exiting"
        return 1
    fi
    
    if [[ $# -eq 2 ]]; then
        unset ENV_FILE
        echo "Using env values file at ${2}"
        ENV_FILE="-f ${2}"
    fi

    unset ENV_FILE
    
    helm package -d $CURRENT_FOLDER --version $VERSION -u $PACKAGE_FOLDER
    helm template $ENV_FILE --version $VERSION --namespace $1 --debug --create-namespace $OUTPUT_FILE
    rm $OUTPUT_FILE
}
