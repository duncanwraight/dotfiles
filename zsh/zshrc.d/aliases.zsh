alias v="nvim"
alias lg="lazygit"
alias whatismyip="curl ifconfig.me"
alias gbranch="ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="git" git rev-parse --abbrev-ref HEAD 2> /dev/null | sed 's/\r//'"

oaws() {
    # Check to see if the first argument exists as a profile in our Okta configuration
    grep "\[$1\]" ~/.okta-aws > /dev/null 2&>1
    if [ $? -ne 0 ]; then
        profile="importio"
    else
        profile=$1
        shift
    fi

    oktacmd="okta-awscli --okta-profile $profile --profile $profile"

    # Check to see if the profile has a default region
    grep -A1 $profile ~/.aws/config | grep region  > /dev/null 2&>1
    if [ $? -ne 0 ]; then
        echo "${profile} doesn't have a default region. Running 'aws configure'..."
        eval "$oktacmd configure"
    fi

    # Run the rest of our arguments as aws CLI commands
    eval "$oktacmd $@"
}

killzoom() {
    ps -aux | grep zoom | grep -v grep | awk '{print $2}' | xargs kill -9
}

killchrome() {
    ps -aux | grep chrome | grep -v grep | awk '{print $2}' | xargs kill -9
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
