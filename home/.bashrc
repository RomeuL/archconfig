#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# mise: gerenciador de versões (ruby, node, python...) — coloca o rails/gems no PATH
command -v mise >/dev/null && eval "$(mise activate bash)"
