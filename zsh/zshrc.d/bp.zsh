# COL_RED=`tput setaf 196`
# COL_GRN=`tput setaf 2`
# COL_LBLUE=`tput setaf 123`
# COL_BLANK=`tput sgr0`

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
        "shared")
            spoke="WS-01NA"
            environment="shared"
            ;;
        "scratch")
            spoke="WS-01VL"
            environment="scratch"
            ;;
        "golden")
            spoke="WS-01VI"
            environment="golden"
            ;;
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9])
            spoke="WS-01MG"
            environment="lab"
            ;;
        *)
            echo "usage: chgaws [lab|dev|sbx|prd|shared|01234567]"
            return 1
            ;;
    esac

    export AWS{_PROFILE,_DEFAULT_PROFILE}="${spoke}-role_DEVOPS"
    echo "Checking for existing AWS authentication..."
    aws sts get-caller-identity > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Not authenticated; running awsconnect"
        awsconnect -b google-chrome
    else
        echo "Already authenticated"
    fi

    echo "Checking for EKS clusters..."
    clusters=("htp-${1}-eks-cluster" "htp-${1}-lab-eks-cluster" "htf-${1}-eks-cluster" "htf-${1}-lab-eks-cluster")

    found_cluster=0

    for cluster in $clusters; do
        echo "Searching for cluster: ${cluster}"
        aws eks list-clusters | jq -e ".clusters | index(\"${cluster}\")" > /dev/null
        if [[ $? -ne 1 ]] ; then
            echo "${COL_GRN}Cluster found${COL_BLANK}"
            found_cluster=1
            aws eks update-kubeconfig --region eu-west-1 --name "${cluster}" --profile $AWS_PROFILE
            return 0
        fi
    done

    if [[ "${found_cluster}" == 0 ]]; then
        echo "${COL_RED}Unable to find a legitimate cluster with this environment/identifier combination${COL_BLANK}"
        return 1
    fi
}

# helmtest() {
#     CURRENT_FOLDER=`realpath .`
#     VERSION="0.1"
#     PACKAGE_FOLDER="./helm/$1"
#     OUTPUT_FILE="./${1}-${VERSION}.tgz"

#     if [[ ! -d "$PACKAGE_FOLDER" ]]; then
#         echo "Folder ${1} does not exist, exiting"
#         return 1
#     fi
    
#     if [[ $# -eq 2 ]]; then
#         unset ENV_FILE
#         echo "Using env values file at ${2}"
#         ENV_FILE="-f ${2}"
#     fi

#     unset ENV_FILE
    
#     helm package -d $CURRENT_FOLDER --version $VERSION -u $PACKAGE_FOLDER
#     helm template $ENV_FILE --version $VERSION --namespace $1 --debug --create-namespace $OUTPUT_FILE
#     rm $OUTPUT_FILE
# }

helmtest() {
    if [ "$#" -gt 1 ]; then
        ENV=$2
    else
        ENV=dev
    fi
    helm package --version 0.1 $1 -u -d ~/Downloads
    helm template --debug -f ./$1/values.yaml -f ./$1/environments/$ENV.yaml --set '.jobs[0].image.repository'=test --create-namespace --version 0.1 ~/Downloads/$1-0.1.tgz 
}

tsup() {
    if [[ $# -lt 1 ]]; then
        echo "Must provide a cluster identifier, e.g. dev|sbx|htp-1234567"
        return 0
    fi

    TS_ENV=$1 terraspace up htp-config -y
    TS_ENV=$1 terraspace all plan

    echo
    read "REPLY?${COL_GRN}Do you want to apply these changes?${COL_BLANK} "
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        TS_ENV=$1 terraspace all up -y
    fi
}

findcluster() {
    rg -i $1 ~/Repos/bp/htf-infrastructure/app/stacks/htp-config -g "*.tfvars"
}
