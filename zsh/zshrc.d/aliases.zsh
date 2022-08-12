alias v="nvim"
alias lg="lazygit"
alias gbranch="ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="git" git rev-parse --abbrev-ref HEAD 2> /dev/null | sed 's/\r//'"

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

killzoom() {
    ps -aux | grep zoom | grep -v grep | awk '{print $2}' | xargs kill -9
}

killchrome() {
    ps -aux | grep chrome | grep -v grep | awk '{print $2}' | xargs kill -9
}

killteams() {
    ps -aux | grep teams | grep -v grep | awk '{print $2}' | xargs kill -9
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
