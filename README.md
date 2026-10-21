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

O resto (disco, bootloader, idioma) fica a seu critério; o fuso horário o script ajusta para o de Brasília.

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
Etapas: `packages shell dotfiles system services flatpak dark-mode theme firefox code-theme`.

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
| `packages/` | pacotes do pacman (`base.txt`, mais `intel.txt` ou `amd.txt` conforme a CPU), do Flatpak e os temas do Omarchy baixados (`themes.txt`) |
| `home/` | dotfiles, espelhando o `$HOME` (lista em `dotfiles.txt`) |
| `system/` | arquivos de `/etc` e `/usr`: tela de login greetd/regreet |
| `extras/` | interface do Firefox (`userChrome.css`) e a extensão "Tema do Sistema" do Code OSS (empacotada na instalação); as cores vêm do tema atual |

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
| SUPER+Esc | menu de energia (bloquear, suspender, reiniciar, desligar, sair) |
| SUPER+SHIFT+T | troca o tema do sistema |
| Print / SHIFT+Print / SUPER+Print | captura de área / tela / janela |

## Temas

**SUPER+SHIFT+T** (ou "Trocar Tema" no launcher) abre a lista de temas, com a paleta de cada um.
Trocar de tema muda o papel de parede, o modo claro/escuro e as cores de tudo:

| Quando | O quê |
|---|---|
| Na hora | Hyprland (bordas), Waybar, wofi, mako, hyprlock, Ghostty, Starship, sugestões do zsh, Fastfetch (cores ANSI do terminal), tooltip dos agentes, apps GTK e o Code OSS (sem recarregar a janela) |
| Ao reabrir o app | Firefox, Dolphin e outros apps Qt/KDE |
| No próximo login | tela de login (regreet) |

Escolher o tema que já está ativo passa para o próximo papel de parede dele.

Os temas usam o formato do [Omarchy](https://github.com/basecamp/omarchy): uma pasta em
`~/.config/theme/themes/<tema>/` com `colors.toml` (a paleta) e `backgrounds/` (papéis de
parede), mais um `lock.<ext>` opcional para a tela de bloqueio.

| Comando | O que faz |
|---|---|
| `theme-set <tema>` | aplica um tema (`--list` lista os instalados) |
| `theme-get <tema>...` | baixa temas oficiais do Omarchy (`--list` mostra todos) |
| `theme-get <url-git>` | baixa um tema da comunidade (só a paleta e as imagens) |
| `theme-set --refresh` | gera de novo os arquivos do tema atual, depois de editar um template |

Como funciona: cada `~/.config/theme/templates/<arquivo>.tpl` vira `~/.config/theme/current/<arquivo>`
com as cores do tema (`{{ accent }}`, `{{ background_strip }}`, `{{ mix background accent 15% }}`…),
e as configs dos apps importam esses arquivos. Para um app novo seguir o tema, basta um
template novo e um import na config dele. Alguns apps leem os arquivos gerados direto:

- o prompt do Starship é o próprio `starship.toml` gerado (o `.zshrc` aponta `STARSHIP_CONFIG` para ele);
- `~/.config/kdeglobals` e `~/.config/qt6ct/qt6ct.conf` são links para os gerados, então mude o
  visual do Qt/KDE nos templates, não pelo qt6ct;
- o theme-set copia as cores para fora de `~/.config/theme` onde é preciso: na extensão "Tema do
  Sistema" do Code OSS, no `chrome/theme.css` do Firefox e em `/var/lib/theme-set` (a tela de login
  roda como o usuário `greeter`, que não enxerga o `$HOME`).

Um tema pode trazer um arquivo pronto com o nome de um template, que substitui o gerado: o
Cyber Arch traz o seu `vscode-theme.json`, feito à mão (o dos outros temas vem do template do Omarchy).

Além das chaves do Omarchy, o `colors.toml` aceita três papéis extras, que o Cyber Arch usa:
`active` (ativo/selecionado), `highlight` (hover) e `alert` (avisos). Nos temas do Omarchy eles
viram o `accent`, o `accent` e o `yellow`.

## Observações

- **Monitores:** as regras do `hyprland.lua` usam a tela do notebook (`eDP-1`) e dois monitores
  externos identificados pelo modelo. Os workspaces 1–5 ficam no `eDP-1`; num PC de mesa (sem
  essa saída), o `~/.config/hypr/workspaces.lua` os põe no primeiro monitor conectado, e só a
  seção de monitores pode precisar de ajuste.
- **Fora do pacman:** Claude Code (instalador oficial), TeamSpeak 6 (tar.xz do site) e
  LocalSend (Flatpak, instalado pelo script).
- **Sem segredos:** tokens, senhas, `.git-credentials` e `.env` nunca entram no repositório.
  Depois de clonar, faça os logins de novo (`gh auth login`, Forgejo, Codex, Tailscale).
