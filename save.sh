#!/usr/bin/env bash
# Copia as configs desta máquina ($HOME e /etc) para o repositório.
# Rode sempre que mudar alguma config e quiser guardar a versão nova (depois: git commit + push).
# O caminho inverso (trazer do GitHub e aplicar nesta máquina) é o ./sync.sh.
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

copy_in() {  # $1 = caminho relativo ao $HOME
    local src="$HOME/$1" dst="$REPO/home/$1"
    [ -e "$src" ] || [ -L "$src" ] || { echo "  (não existe, pulando) $1"; return; }
    rm -rf "$dst"; mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    find "$dst" \( -name '*.bak' -o -name '*.bak-*' -o -name '__pycache__' \) -prune -exec rm -rf {} + 2>/dev/null || true
    # caminhos da pasta pessoal viram um marcador; o install.sh troca pelo $HOME do PC novo
    { grep -rlI --null "$HOME" "$dst" 2>/dev/null || true; } | xargs -0 -r sed -i "s|$HOME|__HOME__|g"
    echo "  $1"
}

echo "==> Dotfiles"
grep -vE '^\s*(#|$)' dotfiles.txt | while IFS= read -r path; do copy_in "$path"; done

echo "==> Sistema (/etc)"
mkdir -p system/etc/greetd
cp /etc/greetd/config.toml /etc/greetd/regreet.toml /etc/greetd/regreet.css system/etc/greetd/ 2>/dev/null || true

echo "==> Extras"
mkdir -p extras/firefox extras/code-theme
prof=$(find "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox" -maxdepth 1 -name '*.default-release' 2>/dev/null | head -1 || true)
if [ -n "$prof" ]; then
    cp "$prof/user.js" extras/firefox/ 2>/dev/null || true
    rm -rf extras/firefox/chrome && cp -a "$prof/chrome" extras/firefox/ 2>/dev/null || true
    rm -f extras/firefox/chrome/theme.css  # link para as cores do theme-set, recriado na instalação
fi
# Só o package.json: as cores da extensão são geradas pelo theme-set
theme=$(find "$HOME/.vscode-oss/extensions" -maxdepth 1 -name 'romeu.theme-picker-*' 2>/dev/null | head -1 || true)
if [ -n "$theme" ]; then
    rm -rf extras/code-theme/extension && mkdir -p extras/code-theme/extension
    cp "$theme/package.json" extras/code-theme/extension/
fi

echo "==> Pacotes (pacman explícitos + flatpak)"
pacman -Qqen > packages/installed-now.txt
flatpak list --user --app --columns=application 2>/dev/null > packages/flatpak.txt || true
echo "Pronto. Revise com: git status && git diff"
