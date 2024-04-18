# COL_GRN=`tput setaf 2`
# COL_LBLUE=`tput setaf 123`
# COL_BLANK=`tput sgr0`

export GITOPS_CLI_ADO_PAT=nxpmbgzre5pbg6w2vxlenddm6ewizflfcr2bi4owqvrcpvrtd6ea

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
    KUBERNETES_VERSION=$(aws eks describe-cluster --name htp-$ENV-eks-cluster | jq -r '.cluster.version')
    helm package --version 0.1 $1 -u -d ~/Downloads
    helm template --kube-version "${KUBERNETES_VERSION:-1.24}" --debug -f ./$1/values.yaml -f ./$1/environments/$ENV.yaml --set '.jobs[0].image.repository'=test --create-namespace --version 0.1 ~/Downloads/$1-0.1.tgz 
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

preprelease() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: preprelease <<env>>"
        return 1
    fi
    chgaws $1
    source ~/Envs/prep-release/bin/activate
    python ~/Repos/bp/htp-tooling-utilities/prep-release/main.py --automated
    deactivate
}

fluxapply() {
    REPOS_DIR="/home/dunc/Repos/bp"
    COL_BLANK=`tput sgr0`
    COL_RED=`tput setaf 9`
    COL_GRN=`tput setaf 10`
    COL_YEL=`tput setaf 11`
    COL_LBUE=`tput setaf 14`
    
    if [[ $# -ne 1 ]]; then
        echo "!!! ${COL_RED}Usage: fluxapply <<cluster_identifier>>${COL_BLANK}"
        return 1
    fi

    CLUSTER="${1}"
    if [[ "${CLUSTER}" =~ '^([a-z]{1,6})-(.*)' ]]; then
        CLUSTER_DIR="${match[1]}/${match[2]}"
        IDENTIFIER="${match[2]}"
    else
        CLUSTER_DIR="${CLUSTER}"
        IDENTIFIER="${CLUSTER}"
    fi

    echo "\n${COL_GRN}fluxapply${COL_BLANK}"
    echo "  Cluster identifier: ${COL_LBLUE}${IDENTIFIER}${COL_BLANK}"
    echo "  Flux directory: ${COL_LBLUE}${CLUSTER_DIR}${COL_BLANK}"

    echo "\n--- ${COL_YEL}Authenticating with cluster${COL_BLANK}\n"

    chgaws "${IDENTIFIER}"
    if [[ $? -ne 0 ]]; then
        echo "!!! ${COL_RED}Unable to authenticate. Exiting...${COL_BLANK}"
        return 1 ;
    fi

    echo "\n--- ${COL_YEL}Applying Flux manifests${COL_BLANK}\n"
    
    kubectl apply -k "${REPOS_DIR}/htp-kubernetes/clusters/${CLUSTER_DIR}"
    if [[ $? -ne 0 ]]; then
        echo "\n--- ${COL_YEL}CRDs probably didn't apply first time; retrying${COL_BLANK}\n"
        kubectl apply -k "${REPOS_DIR}/htp-kubernetes/clusters/${CLUSTER_DIR}"
    fi
    if [[ $? -ne 0 ]]; then
        echo "!!! ${COL_RED}Unable to apply Flux configuration to cluster ${CLUSTER}. Exiting...${COL_BLANK}"
        return 1
    fi
    
    echo "\n--- ${COL_YEL}Process complete${COL_BLANK}\n"
}

obsstackmonitor() {
    if [[ "$#" -ne 1 ]] || [[ ! "${1}" =~ '(loki|tempo|mimir)' ]]; then
        echo "Usage: obsstackmonitor [loki|tempo|mimir]"
        return 1
    fi

    kubectl run "obs-stack-monitor-dwr-${1}" --image=006411612559.dkr.ecr.eu-west-1.amazonaws.com/obs-stack-helper:latest --restart="Never" --rm -i --tty "check-${1}"
}

dbuildpush() {
  RANDSTRING=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13; echo)
  REPO=$2
  ENV=$1
  IMAGE="006411612559.dkr.ecr.eu-west-1.amazonaws.com/container-images/${REPO}:${RANDSTRING}"

  chgaws shared
  aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 006411612559.dkr.ecr.eu-west-1.amazonaws.com

  docker build -t $IMAGE .
  docker push $IMAGE

  chgaws $ENV

  echo "!!! New image tag: ${REPO}:${RANDSTRING}"
}

gitops() {
  /home/dunc/Envs/gitops-cli/bin/python /home/dunc/Repos/bp/htp-kubernetes-tooling/tools/gitops "${@:1}"
}
