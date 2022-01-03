alias v="nvim"
alias lg="lazygit"
alias whatismyip="curl ifconfig.me"
alias gbranch="ZSH_PLUGINS_ALIAS_TIPS_EXCLUDES="git" git rev-parse --abbrev-ref HEAD 2> /dev/null | sed 's/\r//'"

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
