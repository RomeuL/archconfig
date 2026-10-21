# Binários do usuário (claude code, etc.)
export PATH="$HOME/.local/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # o prompt é do Starship (config gerada pelo theme-set, ver abaixo)

# zsh-autosuggestions: sugere em cinza o resto do comando com base no histórico (→ aceita)
# (vem do pacman; link em ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # histórico primeiro, depois a completação normal

# zsh-syntax-highlighting deve ser o último plugin
plugins=(git sudo zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Cores do tema atual (theme-set): o prompt do Starship e a cor das sugestões.
# O arquivo do zsh é relido a cada prompt, então um terminal aberto acompanha a troca de tema.
export STARSHIP_CONFIG="$HOME/.config/theme/current/starship.toml"
_theme_colors() { [[ -r ~/.config/theme/current/zsh.zsh ]] && source ~/.config/theme/current/zsh.zsh }
_theme_colors
precmd_functions+=(_theme_colors)
command -v starship >/dev/null && eval "$(starship init zsh)"

export EDITOR=nano

# Histórico
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS SHARE_HISTORY

# eza no lugar do ls
if command -v eza >/dev/null; then
    # ls: lista com ícones, permissões e tamanho; la: o mesmo incluindo arquivos ocultos (.arquivos)
    alias ls='eza -l --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
fi

# zoxide no lugar do cd: "cd pasta" pula para diretórios usados com frequência (caminhos normais
# continuam funcionando) e "cdi" escolhe interativamente com fzf
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

# mise: gerenciador de versões (node, python, etc.)
command -v mise >/dev/null && eval "$(mise activate zsh)"

# Codex: ao sair, encerra o app-server que ele deixa em segundo plano (~550 MB de RAM),
# a menos que ainda haja outra sessão do Codex aberta
codex() {
    command codex "$@"
    local rc=$?
    if ! pgrep -u "$USER" -a -x codex | command grep -qv 'app-server'; then
        pkill -u "$USER" -f 'codex app-server .*--managed-daemon'
    fi
    return $rc
}

# Mostra o fastfetch ao abrir um terminal (só em shells interativos)
[[ -o interactive ]] && command -v fastfetch >/dev/null && fastfetch
