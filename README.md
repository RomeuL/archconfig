# archconfig

Minha configuração do Arch Linux: **Hyprland + Waybar + Ghostty + zsh**, com o tema
**Cyber Arch** (paleta Cyberpunk 2077: vermelho `#ff003c`, ciano `#00f0ff`, amarelo `#fcee09`).

## PC novo

### 1. archinstall

Rode `archinstall` no pendrive do Arch e escolha:

| Opção | Valor |
|---|---|
| **Profile** | `Minimal` (sem desktop: o script instala o Hyprland e todo o resto) |
| **Audio** | `No audio server` (o script instala o PipeWire) |
| **Network configuration** | `Use NetworkManager` (para ter internet depois do primeiro boot) |
| **Additional packages** | `git` (o único pacote extra) |
| **User account** | seu usuário, marcado como **superuser** (sudo) |

O resto (disco, bootloader, fuso horário, idioma) fica a seu critério.

### 2. Primeiro boot

Entre com seu usuário no terminal (TTY). Se for Wi-Fi, conecte com `nmtui`. Depois:

```sh
git clone https://github.com/RomeuL/archconfig.git
cd archconfig
./install.sh
```

O repositório é público, então o clone não pede login.

### 3. Depois do script

Siga as tarefas que ele lista no final (logins, Claude Code) e **reinicie**: o PC vai abrir
na tela de login gráfica e entrar direto no Hyprland.

Dá para rodar só uma parte: `./install.sh firefox code-theme`.
Etapas: `packages shell dotfiles system services flatpak dark-mode firefox code-theme`.

O script pode ser rodado de novo sem problemas. Tudo que ele substitui vai antes para
`~/.config-backup/archconfig-<data>/`.

## Atualizar o repositório com as configs desta máquina

```sh
./sync.sh          # copia $HOME e /etc para o repositório
git add -A && git commit -m "Atualiza configs" && git push
```

## O que tem aqui

| Pasta | Conteúdo |
|---|---|
| `packages/` | pacotes do pacman (`base.txt`, mais `intel.txt` ou `amd.txt` conforme a CPU) e do Flatpak |
| `home/` | dotfiles, espelhando o `$HOME` (lista em `dotfiles.txt`) |
| `system/` | arquivos de `/etc` e `/usr`: tela de login greetd/regreet |
| `extras/` | tema do Firefox (`userChrome.css`) e tema do Code OSS (empacotado na instalação) |

Caminhos da pasta pessoal aparecem como `__HOME__` no repositório e viram o `$HOME`
do PC novo durante a instalação.

## Atalhos principais

| Atalho | Ação |
|---|---|
| SUPER+Enter | terminal (Ghostty) |
| SUPER+Espaço | launcher (wofi) |
| SUPER+B / C / E / T | Firefox / Code OSS / Dolphin / TeamSpeak |
| SUPER+W | fecha a janela |
| SUPER+F / V | tela cheia / flutuante |
| SUPER+setas | foco · +SHIFT move · +CTRL redimensiona |
| SUPER+1…5 | workspaces do monitor principal |
| SUPER+Z / X | workspaces do monitor externo |
| SUPER+L | bloqueia a tela |
| Print / SHIFT+Print / SUPER+Print | captura de área / tela / janela |

## Observações

- **Monitores:** as regras do `hyprland.lua` usam a tela do notebook (`eDP-1`) e dois monitores
  externos identificados pelo modelo. Os workspaces 1–5 ficam no `eDP-1`; num PC de mesa (sem
  essa saída), o `~/.config/hypr/workspaces.lua` os põe no primeiro monitor conectado, e só a
  seção de monitores pode precisar de ajuste.
- **Fora do pacman:** Claude Code (instalador oficial), TeamSpeak 6 (tar.xz do site) e
  LocalSend (Flatpak, instalado pelo script).
- **Sem segredos:** tokens, senhas, `.git-credentials` e `.env` nunca entram no repositório.
  Depois de clonar, faça os logins de novo (`gh auth login`, Forgejo, Codex, Tailscale).
