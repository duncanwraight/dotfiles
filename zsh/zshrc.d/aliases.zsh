alias python="python3"
alias v="nvim"
alias lg="lazygit"
alias yq="/home/dunc/.local/bin/yq"
alias gbranch="ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES=\"git\" git rev-parse --abbrev-ref HEAD 2> /dev/null | tr -d \" \t\n\r\""

alias k="k -h --group-directories-first"
alias kruncurl="kubectl run curlpod-dwr-$(date +%s) --image=curlimages/curl --rm -i --tty --command -- sh"
alias krungrpccurl="kubectl run grpccurlpod-dwr-$(date +%s) --image=fullstorydev/grpcurl -- "
alias kpendingds="~/Envs/utilities/bin/python3 ~/Tooling/kube-pending-ds-nodes.py"

oaws() {
    if [ "$#" -eq 0 ]; then
        echo "No Okta profile specified; using importio (Okta) and default (AWS) profiles"
        OKTA_PROFILE="importio"
        AWS_PROFILE="default"
    else
        # Check to see if the first argument exists as a profile in our Okta configuration
        grep "\[$1\]" ~/.okta-aws > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "Profile ${1} does not exist in ~/.okta-aws. Using importio (Okta) and default (AWS) profiles"
            OKTA_PROFILE="importio"
            AWS_PROFILE="default"
        else
            echo "Profile ${1} exists in ~/.okta-aws"
            OKTA_PROFILE=$1
            AWS_PROFILE=$1
        fi
    fi

    okta-awscli --okta-profile $OKTA_PROFILE --profile $AWS_PROFILE

    # Check to see if the profile has a default region
    grep -A1 $AWS_PROFILE ~/.aws/config | grep region  > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Profile ${AWS_PROFILE} doesn't have a default region. Running 'aws configure'..."
        aws --profile $AWS_PROFILE configure
    fi
}

killapp() {
    if [[ $# -eq 1 ]]; then
        ps -aux | grep $1 | grep -v grep | awk '{print $2}' | xargs sudo kill -9
    else
        echo "Usage: killapp <<app name as seen in ps>>"
        return 1
    fi
}

killzscaler() {
    for proc in zstunnel zsaservice ZSTray ; do
        ps -aux | grep $proc | grep -v grep | awk '{print $2}' | sudo xargs kill -9
    done
}

gpom() {
    if [ -d .git ]; then
        git show-branch remotes/origin/master >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            BRANCH=main
        else
            BRANCH=master
        fi

        if [[ `git rev-parse --abbrev-ref HEAD` != "${BRANCH}" ]]; then
            git checkout ${BRANCH}
        fi

        git fetch
        git pull origin ${BRANCH}
    else
        echo "$(pwd) is not a Git repository"
    fi
}

chgsnd() {
    if [[ "${1}" == "speakers" ]]; then
        SPEAKERS=$(pactl list short sinks | grep AudioQuest | awk '{print $2}')
        pactl set-default-sink $SPEAKERS
    elif [[ "${1}" == "headphones" ]]; then
        HEADPHONES=$(pactl list short sinks | grep 'pci-' | awk '{print $2}')
        pactl set-default-sink $HEADPHONES
    elif [[ "${1}" == "usb" ]]; then
        USB=$(pactl list short sinks | grep 'Razer' | awk '{print $2}')
        pactl set-default-sink $USB
    else
        echo "Must specify speakers/headphones"
        return 1
    fi
}

#outsecrets() {
#    yq '.data | map_values(. | @base64d)'
#}

outsecrets() {
    kubectl get secret $1 -o yaml | yq '.data | map_values(. | @base64d)'
}

kind() {
    yq ea "[.][] | select(.kind==\"$1\")"
}

alias kns='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'

knodecheck() {
    kubectl get node `kubectl get pod $1 -o yaml | yq -r '.spec.nodeName'` --show-labels
}

kpodrescheck() {
    kubectl get po -o custom-columns="Name:metadata.name,CPU-request:spec.containers[*].resources.requests.cpu,MEM-request:spec.containers[*].resources.requests.memory,CPU-limit:spec.containers[*].resources.limits.cpu, MEM-limit:spec.containers[*].resources.limits.memory"
}

kfindmissingpod() {
  NAMESPACE=$1
  kubectl get nodes --no-headers | awk '{print $1}' | grep -v "$(kubectl get pods -o=custom-columns=NAME:.spec.nodeName -n $NAMESPACE | sort -u)"
}

gpp() {
    git checkout $1
    git pull origin $1
    git push origin $1
}

alias fluxrestart='f() { flux suspend helmrelease -n $1 $1 && flux resume helmrelease -n $1 $1 } ; f'
alias fluxsuspend='f() { flux suspend kustomization -n flux-system application-$1 && flux suspend helmrelease $1 -n $1 } ; f'
alias fluxresume='f() { flux resume helmrelease $1 -n $1 && flux resume kustomization -n flux-system application-$1 } ; f'

wipe_ecr_repo() {
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: wipe_ecr_repo <<repository_name>>"
        return 1
    fi

    if [ -z ${AWS_PROFILE+x} ]; then
        echo "AWS_PROFILE variable is not set"
        return 1
    fi

    if [[ "${AWS_PROFILE}" =~ "WS-01NA" ]]; then
        echo "Cannot wipe repositories on Shared spoke"
        return 1
    fi

    echo "Wiping repository ${1} using role ${AWS_PROFILE}"
    aws ecr batch-delete-image --region eu-west-1 \
        --repository-name $1 \
        --image-ids "$(aws ecr list-images --region eu-west-1 --repository-name $1 --query 'imageIds[*]' --output json)" | jq || true
}

helmchartdownload() {
    if [[ $? -ne 1 ]]; then
        PORT=3999
        APPLICATION=$1
        kubectl port-forward -n flux-system service/source-controller "$PORT":80 &
        curl http://localhost:$PORT/helmchart/flux-system/$APPLICATION-$APPLICATION/latest.tar.gz --output ~/Downloads/$APPLICATION.tar.gz
        tar -zxf latest.tar.gz
        ls -halt ~/Downloads/$APPLICATION
        killapp port-forward
    else
        echo "Usage: helmchartdownload <<chart-name>>"
    fi
}

alias owtank="python ~/Documents/ow-tank-selection.py"
watch() {
    if [[ "$#" -lt 1 ]]; then
        echo "Usage: watch [helmrelease|kustomization|pods]"
        return 1
    fi

    if [[ "$#" -eq 2 ]]; then
        namespace="-n ${2}"
    else
        namespace="-A"
    fi

    /usr/bin/watch -n 2 "kubectl get ${1} ${namespace}"
}

kgetall() {
  for res in $(kubectl api-resources --verbs=list --namespaced -o name | grep -v 'event'); do 
    echo "--- $res"
    kubectl get --show-kind --ignore-not-found $res
  done
}
