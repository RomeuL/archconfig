# archconfig

Minha configuração do Arch Linux: **Hyprland + Waybar + Ghostty + zsh**, com o tema
**Cyber Arch** (paleta Cyberpunk 2077: vermelho `#ff003c`, ciano `#00f0ff`, amarelo `#fcee09`).

## PC novo

1. Instale o Arch com o `archinstall` (perfil mínimo, NetworkManager, seu usuário com sudo).
2. Entre no seu usuário e rode:

   ```sh
   sudo pacman -S --needed git
   git clone https://github.com/<seu-usuario>/archconfig.git
   cd archconfig
   ./install.sh
   ```

3. Siga as tarefas que o script lista no final (logins, Claude Code, reiniciar).

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
  externos identificados pelo modelo. Num PC de mesa, ajuste a seção de monitores e o
  `~/.config/hypr/workspaces.lua` (que fixa os workspaces 1–5 no `eDP-1`).
- **Fora do pacman:** Claude Code (instalador oficial), TeamSpeak 6 (tar.xz do site) e
  LocalSend (Flatpak, instalado pelo script).
- **Sem segredos:** tokens, senhas, `.git-credentials` e `.env` nunca entram no repositório.
  Depois de clonar, faça os logins de novo (`gh auth login`, Forgejo, Codex, Tailscale).
