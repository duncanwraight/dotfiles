source <(kubectl completion zsh)
source <(helm completion zsh)
source ~/.zshrc.d/az.completion
complete -C "$(which aws_completer)" aws
