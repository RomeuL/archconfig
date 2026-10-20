#!/usr/bin/env bash
# Deixa um Arch Linux recém-instalado (archinstall) com a minha configuração:
# Hyprland + Waybar + Ghostty + zsh, tema Cyber Arch, apps e serviços.
#
# Uso:
#   ./install.sh            tudo
#   ./install.sh <etapa>... só as etapas indicadas (ex.: ./install.sh firefox code-theme)
#
# Etapas: packages shell dotfiles system services flatpak dark-mode firefox code-theme
#
# Pode ser rodado de novo sem problemas: pacotes já instalados são pulados e todo arquivo
# substituído vai antes para ~/.config-backup/archconfig-<data>/.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.config-backup/archconfig-$STAMP"
NOTES=()   # tarefas manuais mostradas no final

say()  { printf '\n\033[1;31m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
note() { NOTES+=("$*"); }

list() { grep -vE '^\s*(#|$)' "$1"; }   # linhas de um arquivo de lista, sem comentários

cpu_vendor() {
    case "$(grep -m1 '^vendor_id' /proc/cpuinfo)" in
        *GenuineIntel*) echo intel ;;
        *AuthenticAMD*) echo amd ;;
        *) echo other ;;
    esac
}

# ---------------------------------------------------------------- etapas

step_packages() {
    say "Pacotes (pacman)"
    local pkgs; mapfile -t pkgs < <(list "$REPO/packages/base.txt")
    local vendor; vendor="$(cpu_vendor)"
    if [ -f "$REPO/packages/$vendor.txt" ]; then
        info "CPU $vendor: incluindo packages/$vendor.txt"
        mapfile -t -O "${#pkgs[@]}" pkgs < <(list "$REPO/packages/$vendor.txt")
    fi
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
}

step_shell() {
    say "Shell: zsh + Oh My Zsh + plugins"
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    else
        info "Oh My Zsh já instalado"
    fi
    # Os plugins vêm do pacman; aqui só ligamos cada um ao Oh My Zsh
    local plugins="$HOME/.oh-my-zsh/custom/plugins" name
    for name in zsh-autosuggestions zsh-syntax-highlighting; do
        rm -rf "${plugins:?}/$name"
        mkdir -p "$plugins/$name"
        printf 'source /usr/share/zsh/plugins/%s/%s.zsh\n' "$name" "$name" > "$plugins/$name/$name.plugin.zsh"
    done
    if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
        sudo chsh -s /usr/bin/zsh "$USER"
        note "Saia e entre de novo na sessão para o zsh virar o shell padrão."
    fi
}

step_dotfiles() {
    say "Dotfiles (backup do que existir em $BACKUP)"
    local path src dst
    while IFS= read -r path; do
        src="$REPO/home/$path"; dst="$HOME/$path"
        [ -e "$src" ] || continue
        if [ -e "$dst" ] || [ -L "$dst" ]; then
            mkdir -p "$(dirname "$BACKUP/$path")"
            mv "$dst" "$BACKUP/$path"
        fi
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        # __HOME__ no repositório = pasta pessoal deste PC
        { grep -rlI --null '__HOME__' "$dst" 2>/dev/null || true; } | xargs -0 -r sed -i "s|__HOME__|$HOME|g"
        info "$path"
    done < <(list "$REPO/dotfiles.txt")
    chmod +x "$HOME"/.local/bin/pkg-* "$HOME"/.claude/statusline.py "$HOME"/.claude/hooks/*.sh \
             "$HOME"/.config/hypr/scripts/*.sh "$HOME"/.config/waybar/scripts/*.py 2>/dev/null || true
    [ -d "$BACKUP" ] && info "Arquivos antigos guardados em $BACKUP"
}

step_system() {
    say "Sistema: tela de login, idioma, teclado, Wi-Fi"
    sudo install -Dm644 "$REPO/system/etc/greetd/config.toml"  /etc/greetd/config.toml
    sudo install -Dm644 "$REPO/system/etc/greetd/regreet.toml" /etc/greetd/regreet.toml
    sudo install -Dm644 "$REPO/system/etc/greetd/regreet.css"  /etc/greetd/regreet.css
    sudo install -Dm644 "$REPO/system/usr/share/backgrounds/regreet/wallpaper.png" \
                        /usr/share/backgrounds/regreet/wallpaper.png
    # A saudação da tela de login usa o nome deste usuário
    sudo sed -i "s/^greeting_msg = .*/greeting_msg = \"Bem-vindo, $USER\"/" /etc/greetd/regreet.toml

    # Idioma: sistema em inglês, datas em português (como no notebook)
    sudo sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' -e 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
    sudo locale-gen >/dev/null
    sudo localectl set-locale LANG=en_US.UTF-8 LC_TIME=pt_BR.UTF-8
    sudo localectl set-keymap br-abnt2
    sudo localectl set-x11-keymap br abnt2

    # Região do Wi-Fi (canais e potência do Brasil)
    sudo sed -i 's/^#WIRELESS_REGDOM="BR"/WIRELESS_REGDOM="BR"/' /etc/conf.d/wireless-regdom
}

step_services() {
    say "Serviços"
    local svcs=(NetworkManager bluetooth docker power-profiles-daemon tailscaled)
    [ "$(cpu_vendor)" = intel ] && svcs+=(thermald)
    sudo systemctl enable "${svcs[@]}"
    info "habilitados: ${svcs[*]}"

    # Tela de login: só troca se não houver outro gerenciador de login configurado
    local dm; dm="$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)"
    if [ -z "$dm" ] || [[ "$dm" == *greetd* ]]; then
        sudo systemctl enable greetd
    else
        note "Já existe outra tela de login ($dm). Para usar a greetd: sudo systemctl enable -f greetd"
    fi

    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service 2>/dev/null || true
    if ! id -nG "$USER" | grep -qw docker; then
        sudo usermod -aG docker "$USER"
        note "Você entrou no grupo docker: vale a partir do próximo login."
    fi
}

step_flatpak() {
    say "Flatpak (Flathub)"
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    local apps; mapfile -t apps < <(list "$REPO/packages/flatpak.txt")
    [ "${#apps[@]}" -gt 0 ] && flatpak install --user -y --noninteractive flathub "${apps[@]}"
}

step_dark_mode() {
    say "Modo escuro para os apps (GTK/libadwaita/Electron)"
    local gs=(gsettings)
    [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && gs=(dbus-run-session gsettings)
    "${gs[@]}" set org.gnome.desktop.interface color-scheme 'prefer-dark'
    "${gs[@]}" set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
}

step_firefox() {
    say "Firefox: tema Cyber Arch"
    local prof
    prof="$(find "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox" -maxdepth 1 -name '*.default-release' 2>/dev/null | head -1 || true)"
    if [ -z "$prof" ]; then
        note "Abra o Firefox uma vez, feche e rode: $REPO/install.sh firefox"
        info "perfil do Firefox ainda não existe, pulando"
        return
    fi
    install -Dm644 "$REPO/extras/firefox/user.js" "$prof/user.js"
    mkdir -p "$prof/chrome" && cp -a "$REPO/extras/firefox/chrome/." "$prof/chrome/"
    info "aplicado em $prof (reinicie o Firefox)"
}

step_code_theme() {
    say "Code OSS: tema Cyber Arch"
    command -v code >/dev/null || { info "code não instalado, pulando"; return; }
    local vsix; vsix="$(mktemp --suffix=.vsix)"
    # Empacota extras/code-theme/extension como .vsix e instala
    python3 - "$REPO/extras/code-theme/extension" "$vsix" <<'PY'
import json, os, sys, zipfile
src, out = sys.argv[1], sys.argv[2]
pkg = json.load(open(os.path.join(src, "package.json")))
manifest = f'''<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{pkg["name"]}" Version="{pkg["version"]}" Publisher="{pkg["publisher"]}"/>
    <DisplayName>{pkg["displayName"]}</DisplayName>
    <Description xml:space="preserve">{pkg["description"]}</Description>
    <Categories>Themes</Categories>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="{pkg["engines"]["vscode"]}"/></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>'''
types = ('<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
         '<Default Extension=".json" ContentType="application/json"/>'
         '<Default Extension=".vsixmanifest" ContentType="text/xml"/></Types>')
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", types)
    z.writestr("extension.vsixmanifest", manifest)
    for root, _, files in os.walk(src):
        for f in files:
            full = os.path.join(root, f)
            z.write(full, os.path.join("extension", os.path.relpath(full, src)))
PY
    code --install-extension "$vsix" --force >/dev/null 2>&1 && info "tema instalado"
    rm -f "$vsix"
}

# ---------------------------------------------------------------- execução

ALL=(packages shell dotfiles system services flatpak dark-mode firefox code-theme)

[ "$(id -u)" -eq 0 ] && { echo "Rode como seu usuário (sem sudo); o script pede a senha quando precisar."; exit 1; }
[ -f /etc/arch-release ] || { echo "Este script é para Arch Linux."; exit 1; }

steps=("$@"); [ "${#steps[@]}" -eq 0 ] && steps=("${ALL[@]}")
sudo -v   # pede a senha uma vez no começo
for s in "${steps[@]}"; do
    case "$s" in
        packages|shell|dotfiles|system|services|flatpak|dark-mode|firefox|code-theme)
            "step_${s//-/_}" ;;
        *) echo "Etapa desconhecida: $s (opções: ${ALL[*]})"; exit 1 ;;
    esac
done

say "Pronto!"
if [ "$#" -eq 0 ]; then
    note "Instale o Claude Code: curl -fsSL https://claude.ai/install.sh | bash"
    note "Faça login: gh auth login · codex · sudo tailscale up"
    note "Reinicie o computador para entrar pela nova tela de login (greetd)."
fi
for n in "${NOTES[@]}"; do printf '  • %s\n' "$n"; done
