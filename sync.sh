#!/usr/bin/env bash
# Traz as mudanças do GitHub (git pull) e aplica nesta máquina só o que mudou desde a última
# sincronização: dotfiles, pacotes novos, tela de login, temas, Firefox e Code OSS.
#
# Uso:
#   ./sync.sh                   git pull + aplica
#   ./sync.sh --no-pull         só aplica (o git pull já foi feito, ou está sem internet)
#   ./sync.sh --since <commit>  aplica tudo que mudou desde esse commit
#
# Só os dotfiles que mudaram no repositório são tocados; os outros ficam como estão aqui. Se um
# deles também foi mudado nesta máquina, as duas mudanças são juntadas; se mexerem nas mesmas
# linhas, fica a do repositório. Nos dois casos a versão daqui vai antes para
# ~/.config-backup/archconfig-<data>/. Pacotes que saíram das listas não são desinstalados:
# o script só avisa.
#
# O caminho inverso (guardar no repositório as configs desta máquina) é o ./save.sh.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
# Etapas e funções do install.sh (say, info, note, step_*...), sem executar a instalação
source "$REPO/install.sh"

changed() { ! git diff --quiet "$BASE" HEAD -- "$@"; }   # algum desses caminhos mudou?

list_at() {  # linhas de uma lista do repositório no commit $1, sem comentários
    git show "$1:$2" 2>/dev/null | grep -vE '^\s*(#|$)' || true
}

pkgs_at() {  # pacotes das listas (base + a da CPU) no commit $1
    { list_at "$1" packages/base.txt; list_at "$1" "packages/$(cpu_vendor).txt"; } | sort -u
}

step_code() {  # código de uma função do install.sh no commit $1
    git show "$1:install.sh" 2>/dev/null | awk -v f="$2() {" '$0 == f {p = 1} p {print} p && /^}$/ {exit}' || true
}

trigger() {  # arquivos do repositório que pedem cada etapa do install.sh
    case "$1" in
        system)     changed system ;;
        flatpak)    changed packages/flatpak.txt ;;
        theme)      changed packages/themes.txt ;;
        firefox)    changed extras/firefox ;;
        code-theme) changed extras/code-theme ;;
        *)          return 1 ;;
    esac
}

# ---------------------------------------------------------------- dotfiles

listed() {  # $2 (caminho relativo ao $HOME) está numa entrada do dotfiles.txt do commit $1?
    local entry
    while IFS= read -r entry; do
        if [ "$2" = "$entry" ] || [[ "$2" == "$entry"/* ]]; then return 0; fi
    done < <(list_at "$1" dotfiles.txt)
    return 1
}

mode_at() { git ls-tree "$1" -- "home/$2" | cut -d' ' -f1; }

blob() {  # home/$2 no commit $1, como fica no $HOME (com o __HOME__ trocado), salvo em $3
    git cat-file blob "$1:home/$2" > "$3"
    if grep -qI __HOME__ "$3"; then sed -i "s|__HOME__|$HOME|g" "$3"; fi
}

same() {  # $HOME/$2 é igual ao home/$2 do commit $1? (conteúdo, link e permissão de execução)
    local dst="$HOME/$2" mode x=644
    mode="$(mode_at "$1" "$2")"
    if [ "$mode" = 120000 ]; then
        [ -L "$dst" ] && [ "$(readlink "$dst")" = "$(git cat-file blob "$1:home/$2")" ]
        return
    fi
    [ -f "$dst" ] && [ ! -L "$dst" ] || return 1
    [ -x "$dst" ] && x=755
    [ "$mode" = "100$x" ] && blob "$1" "$2" "$TMP/blob" && cmp -s "$TMP/blob" "$dst"
}

put() {  # copia home/$1 do repositório para o $HOME
    local dst="$HOME/$1"
    mkdir -p "$(dirname "$dst")"
    rm -rf -- "$dst"
    cp -a "$REPO/home/$1" "$dst"
    if [ ! -L "$dst" ] && grep -qI __HOME__ "$dst"; then sed -i "s|__HOME__|$HOME|g" "$dst"; fi
}

merge() {  # junta em $HOME/$1 as mudanças daqui e as do repositório (só texto; falha se baterem)
    local dst="$HOME/$1"
    [ -f "$dst" ] && [ ! -L "$dst" ] || return 1
    case "$(mode_at "$BASE" "$1") $(mode_at HEAD "$1")" in
        100*" "100*) ;;
        *) return 1 ;;
    esac
    blob "$BASE" "$1" "$TMP/base"
    blob HEAD "$1" "$TMP/repo"
    cp "$dst" "$TMP/local"
    git merge-file -q "$TMP/local" "$TMP/base" "$TMP/repo" 2>/dev/null || return 1
    cat "$TMP/local" > "$dst"   # mantém as permissões do arquivo daqui
}

update_file() {  # $1 (caminho relativo ao $HOME) mudou ou surgiu no repositório
    local rel="$1" dst="$HOME/$1"
    if same HEAD "$rel"; then return 0; fi   # já está igual
    DONE=$((DONE + 1))
    if { [ ! -e "$dst" ] && [ ! -L "$dst" ]; } || same "$BASE" "$rel"; then
        put "$rel"; info "$rel"              # não foi mudado aqui: só atualiza
        return 0
    fi
    mkdir -p "$(dirname "$BACKUP/$rel")"
    cp -a "$dst" "$BACKUP/$rel"
    SAVED=1
    if merge "$rel"; then
        info "$rel (juntado com as mudanças daqui)"
    else
        put "$rel"
        info "$rel (conflito: ficou a versão do repositório)"
        note "$rel: as mudanças daqui e as do repositório mexem nas mesmas linhas; ficou a do repositório e a daqui está em $BACKUP/$rel"
    fi
}

remove_file() {  # $1 saiu do repositório: apaga, se não foi mudado aqui
    local rel="$1" dst="$HOME/$1" dir
    if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then return 0; fi
    DONE=$((DONE + 1))
    if same "$BASE" "$rel"; then
        rm -f -- "$dst"
        info "$rel (removido)"
        dir="$(dirname "$dst")"   # e as pastas que ficaram vazias
        while [ "$dir" != "$HOME" ] && rmdir -- "$dir" 2>/dev/null; do dir="$(dirname "$dir")"; done
    else
        note "$rel saiu do repositório, mas tinha mudanças daqui: ficou como está"
    fi
}

# ---------------------------------------------------------------- execução

main() {
    local pull=1 since=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --no-pull) pull=0 ;;
            --since)
                [ "$#" -ge 2 ] || { echo "Faltou o commit: ./sync.sh --since <commit>"; exit 1; }
                since="$2"; shift ;;
            -h|--help) awk 'NR > 1 && /^#/ {sub(/^# ?/, ""); print; next} NR > 1 {exit}' "$0"; return ;;
            *) echo "Opção desconhecida: $1 (veja ./sync.sh --help)"; exit 1 ;;
        esac
        shift
    done
    [ "$(id -u)" -eq 0 ] && { echo "Rode como seu usuário (sem sudo); o script pede a senha quando precisar."; exit 1; }

    cd "$REPO"
    if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
        echo "O repositório tem mudanças que não foram commitadas (veja: git status)."
        echo "Faça o commit delas (e o push), ou descarte com: git restore ."
        exit 1
    fi

    local before orig
    before="$(git rev-parse HEAD)"
    orig="$(git rev-parse -q --verify ORIG_HEAD || true)"   # um git pull feito à mão guarda aqui o commit de antes
    if [ "$pull" = 1 ]; then
        say "Baixando as mudanças do GitHub"
        if ! git pull --ff-only; then
            echo "O git pull falhou: sem internet, ou há commits daqui que não estão no GitHub"
            echo "(nesse caso: git pull --rebase && git push). Para aplicar só o que já foi baixado: ./sync.sh --no-pull"
            exit 1
        fi
    fi

    # Desde quando aplicar: a última sincronização (ou instalação completa); na primeira vez,
    # o commit de antes do último git pull
    if [ -z "$since" ]; then
        if [ -s "$STATE" ]; then
            since="$(cat "$STATE")"
        elif [ -n "$orig" ] && git merge-base --is-ancestor "$orig" "$before"; then
            since="$orig"
        else
            since="$before"
        fi
    fi
    BASE="$(git rev-parse -q --verify "$since^{commit}")" || {
        echo "O commit $since não existe neste repositório. Escolha outro: ./sync.sh --since <commit>"
        exit 1
    }

    # O pull trouxe uma versão nova deste script ou do install.sh: continua com ela
    if [ "$pull" = 1 ] && ! git diff --quiet "$before" HEAD -- sync.sh install.sh; then
        exec bash "$REPO/sync.sh" --no-pull --since "$BASE"
    fi

    if [ "$BASE" = "$(git rev-parse HEAD)" ]; then
        echo "Nada novo para aplicar: esta máquina já está em $(git log -1 --format='%h (%s)')."
        mark_applied
        return
    fi
    say "Aplicando as mudanças desde $(git log -1 --format='%h (%s)' "$BASE")"
    git log --format='    %h %s' "$BASE..HEAD"

    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT

    # Etapas do install.sh com arquivos mudados ou com o código mudado (inclusive etapas novas).
    # Os dotfiles não: são aplicados aqui, arquivo por arquivo, para não sobrescrever o resto
    local steps=() s
    for s in "${ALL[@]}"; do
        [ "$s" = dotfiles ] && continue
        if [ "$(step_code "$BASE" "step_${s//-/_}")" != "$(step_code HEAD "step_${s//-/_}")" ] || trigger "$s"; then
            steps+=("$s")
        fi
    done

    # Pacotes que entraram nas listas e ainda não estão instalados
    local added=() gone=() missing=()
    mapfile -t added < <(comm -13 <(pkgs_at "$BASE") <(pkgs_at HEAD))
    mapfile -t gone  < <(comm -23 <(pkgs_at "$BASE") <(pkgs_at HEAD))
    if [ "${#added[@]}" -gt 0 ]; then mapfile -t missing < <(pacman -T "${added[@]}" || true); fi
    if [[ " ${steps[*]} " == *" packages "* ]]; then
        step_packages
    elif [ "${#missing[@]}" -gt 0 ]; then
        say "Pacotes novos: ${missing[*]}"
        # O Arch não aceita instalar sem atualizar o resto (atualização parcial quebra o sistema)
        sudo pacman -Syu --needed --noconfirm "${missing[@]}"
    fi

    say "Dotfiles"
    local path rel
    DONE=0 SAVED=0
    while IFS= read -r -d '' path; do
        rel="${path#home/}"
        if git cat-file -e "HEAD:$path" 2>/dev/null; then
            if listed HEAD "$rel"; then update_file "$rel"; fi
        elif listed "$BASE" "$rel"; then
            remove_file "$rel"
        fi
    done < <(git diff -z --no-renames --name-only "$BASE" HEAD -- home)
    [ "$DONE" -gt 0 ] || info "nada a mudar"
    if [ "$SAVED" = 1 ]; then info "Versões daqui guardadas em $BACKUP"; fi

    for s in "${steps[@]}"; do
        [ "$s" = packages ] || "step_${s//-/_}"
    done

    if changed home || [ "${#steps[@]}" -gt 0 ]; then
        say "Recarregando os apps"
        if "$HOME/.local/bin/theme-set" --refresh; then
            info "tema gerado de novo; Hyprland, Waybar, swaync e Ghostty recarregados"
        else
            note "O theme-set --refresh falhou (veja a mensagem acima)."
        fi
        if changed home/.config/swaync; then swaync-client --reload-config >/dev/null 2>&1 || true; fi
        if changed home/.config/hypr/hypridle.conf; then
            if "$HOME/.local/bin/arch-lock" reload-idle; then
                info "hypridle recarregado com os novos tempos de bloqueio e energia"
            else
                note "Não foi possível recarregar o hypridle. Saia e entre novamente na sessão."
            fi
        fi
    fi

    if [ "${#gone[@]}" -gt 0 ]; then mapfile -t gone < <(pacman -Qq "${gone[@]}" 2>/dev/null || true); fi
    if [ "${#gone[@]}" -gt 0 ]; then
        note "Saíram da lista de pacotes e continuam instalados: ${gone[*]}. Para desinstalar: sudo pacman -Rns ${gone[*]}"
    fi
    if [ "${#missing[@]}" -gt 0 ] || grep -qE '^[+-] *hl\.exec_cmd\(' < <(git diff "$BASE" HEAD -- home/.config/hypr); then
        note "Saia e entre de novo na sessão: programas que abrem no login e fontes novas só valem a partir daí."
    fi

    mark_applied
    say "Pronto! Esta máquina está em $(git log -1 --format='%h (%s)')"
    for n in "${NOTES[@]}"; do printf '  • %s\n' "$n"; done
}

main "$@"; exit
