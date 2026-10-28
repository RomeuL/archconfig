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

## Sincronizar entre PCs

No PC onde mudou alguma config, guarde no repositório:

```sh
./save.sh          # copia $HOME e /etc para o repositório
git add -A && git commit -m "Atualiza configs" && git push
```

Nos outros, traga e aplique:

```sh
./sync.sh          # git pull + aplica só o que mudou desde a última sincronização
```

O `sync.sh` mexe só nos dotfiles que mudaram no repositório (os outros ficam como estão),
instala os pacotes que entraram nas listas e roda as etapas do `install.sh` que forem
precisas (tela de login, temas, Firefox, Code OSS); no fim, recarrega o tema e os apps.
Se um dotfile também foi mudado no PC, as duas mudanças são juntadas; se mexerem nas mesmas
linhas, fica a do repositório. Nos dois casos a versão do PC vai antes para
`~/.config-backup/`. Pacotes que saíram das listas não são desinstalados, só avisados.

Ele lembra do último commit aplicado (em `~/.local/state/archconfig/applied`). Também
funciona depois de um `git pull` feito à mão, e `./sync.sh --since <commit>` reaplica tudo
desde um commit.

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
| SUPER+SHIFT+S | captura de área direto para a área de transferência |
| SUPER+S / SUPER+ALT+S | mostra o workspace escondido (scratchpad) / manda a janela para ele |

## Temas

### Bloqueio animado

O `hypridle` bloqueia a sessão após **5 minutos**. O bloqueio animado usa Quickshell
(pacote oficial do Arch), com uma cena própria para cada tema instalado. As cores e a
fonte também vêm do tema atual. A seleção acompanha a troca de tema. Mover o mouse ou
pressionar uma tecla mostra a senha; somente a autenticação pelo PAM do Hyprlock libera
a sessão. A prévia abre uma janela comum e não verifica senhas.

```sh
sudo pacman -Syu --needed quickshell upower
arch-lock preview             # ver o visual, sem bloquear
arch-lock preview tron-arcade # prévia de outro tema sem mudar o desktop
arch-lock enable              # ativa e recarrega o hypridle
arch-lock                     # testar o bloqueio e a senha
```

Na tomada, a tela permanece ligada. Na bateria, as animações usam 12 quadros por segundo,
a tela apaga aos **10 minutos** de inatividade e o notebook suspende aos **30 minutos**.
As animações são pausadas quando o hypridle apaga a tela e retomadas quando ela acende.
Os tempos ficam em `~/.config/hypr/hypridle.conf`; os quadros por segundo e o tempo do
campo de senha ficam em `~/.config/quickshell/arch-lock/settings.json`.

| Tema | Animação |
|---|---|
| Tron Arcade | Arena neon, duas motos com rastros ciano/laranja e disco giratório |
| Cyber Arch | Distrito cyberpunk com chuva, letreiros neon e drone |
| Tokyo Night | Cidade noturna, torre iluminada e trem passando |
| Catppuccin | Café cósmico com gato sonolento e planetas em órbita |
| Catppuccin Latte | Janela ensolarada, nuvens, planta e café com vapor |
| Gruvbox | Engrenagens e osciloscópio em tons quentes |
| Nord | Aurora boreal, montanhas e neve |
| Rosé Pine | Jardim florido com pétalas ao vento e reflexos na água |
| Kanagawa | Ondas, espuma, barco e monte ao fundo |
| Everforest | Floresta em camadas, névoa e vagalumes |

As cenas são desenhadas em `ThemeScenes.js`, sem vídeos ou downloads. Temas desconhecidos
recebem uma cena de constelações. A superfície de desenho tem altura máxima de 720 pixels
para limitar o trabalho em telas grandes; textos e senha continuam na resolução da tela.
A superfície é ampliada para ocupar cada monitor por inteiro, inclusive ultrawide.
O bloqueio cria uma tela por monitor e acompanha resoluções, escalas e conexão/desconexão
de monitores. É possível desbloquear em qualquer tela, liberando a sessão inteira.

`arch-lock disable` faz os próximos bloqueios voltarem ao Hyprlock; `arch-lock status`
mostra o estado. A ativação é local a cada PC e não entra no Git. Sem ativação ou sem
Quickshell, o Hyprlock continua sendo usado. Erros de inicialização também tentam abrir
o Hyprlock; os logs ficam em `~/.local/state/arch-lock/lock.log`. Uma falha depois de obter
o bloqueio pode exigir recuperação pela sessão/TTY; valide senha, monitor externo e retorno
da suspensão na sua máquina antes de depender deste bloqueio.

O atalho **SUPER+L**, o menu de energia e o bloqueio antes da suspensão continuam passando
por `loginctl lock-session`, que aciona o comando configurado no hypridle.
O Hyprland inicia o hypridle pelo serviço de usuário do systemd, para ele continuar
rodando após fechar o terminal e ser reiniciado em caso de falha.

Validação local (sem bloquear a sessão e sem usar senhas reais):

```sh
python -m unittest discover -s tests -v
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    /usr/lib/qt6/bin/qmltestrunner -input tests/qml -o -,txt
```

Os testes cobrem o controlador com um transporte PAM simulado, os campos da interface,
as dez cenas (movimento e composições distintas com a mesma paleta) e o lançador com
comandos simulados. Não substituem a validação da
autenticação PAM real, do protocolo de bloqueio e da suspensão na sessão gráfica.

Para verificar o renderizador gráfico real em uma sessão isolada, sem bloquear o desktop:

```sh
python tests/check_lock_displays.py
```

Esse teste exige uma sessão Wayland e `ffmpeg`. Abre um compositor de teste com ultrawide,
tela a 150% e monitor vertical; verifica as bordas da animação, redimensionamento e troca
de monitores durante o bloqueio. As capturas ficam em uma pasta temporária indicada na saída.

### Aparência do sistema

**SUPER+SHIFT+T** (ou "Trocar Tema" no launcher) abre a lista de temas, com a paleta de cada um.
Trocar de tema muda o papel de parede, o modo claro/escuro e as cores de tudo:

| Quando | O quê |
|---|---|
| Na hora | Hyprland (bordas), Waybar, wofi, central de notificações (swaync), hyprlock, Ghostty, Starship, sugestões do zsh, Fastfetch (cores ANSI do terminal), tooltip dos agentes, apps GTK e o Code OSS (sem recarregar a janela) |
| Ao reabrir o app | Firefox, Dolphin e outros apps Qt/KDE |
| No próximo login | tela de login (regreet) |

Escolher o tema que já está ativo passa para o próximo papel de parede dele.

Os temas usam o formato do [Omarchy](https://github.com/basecamp/omarchy): uma pasta em
`~/.config/theme/themes/<tema>/` com `colors.toml` (a paleta) e `backgrounds/` (papéis de
parede), mais um `lock.<ext>` opcional para a tela de bloqueio.

Temas daqui: **Cyber Arch** (o padrão) e **Tron Arcade** (Tron com fliperama em pixel art:
fonte BigBlueTerminal de PC antigo, cantos retos, brilho neon nas janelas, barra de HUD de ponta
a ponta e papéis de parede de grade neon gerados por `gerar-papeis-de-parede.py`).

Além das cores, um tema pode mudar o estilo do sistema com um `style.toml` na pasta dele, só
com o que muda em relação ao padrão (`~/.config/theme/style.toml`): fontes e tamanhos, cantos
(`rounding`), bordas e espaços entre janelas, opacidade, vidro fosco, sombra (`shadow_sharp` e
`shadow_offset` dão a sombra dura de pixel art), brilho neon (`glow`) e a tela de bloqueio.
Para mudar algo mais a fundo, o tema traz um template próprio com o nome de um padrão: o Tron
Arcade traz `waybar.css.tpl` e `waybar.jsonc.tpl` (outra barra e outros rótulos de workspace).
Uma fonte recém-instalada só aparece nos apps abertos depois da instalação: reabra-os (ou saia
e entre de novo na sessão).

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
- o estilo da Waybar, do wofi e da tela de login são os gerados (`waybar.css`, `wofi.css`,
  `login.css`), e a altura, as margens e os rótulos dos workspaces vêm do `waybar.jsonc` que a
  `~/.config/waybar/config.jsonc` inclui;
- `~/.config/kdeglobals` e `~/.config/qt6ct/qt6ct.conf` são links para os gerados, então mude o
  visual do Qt/KDE nos templates, não pelo qt6ct;
- o theme-set copia as cores para fora de `~/.config/theme` onde é preciso: na extensão "Tema do
  Sistema" do Code OSS, no `chrome/theme.css` do Firefox e em `/var/lib/theme-set` (a tela de login
  roda como o usuário `greeter`, que não enxerga o `$HOME`).

Um tema pode trazer um arquivo pronto com o nome de um template, que substitui o gerado: o
Cyber Arch traz o seu `vscode-theme.json`, feito à mão (o dos outros temas vem do template do Omarchy).
O `theme-get` só baixa dados (paleta e imagens), nunca templates ou arquivos prontos.

Além das chaves do Omarchy, o `colors.toml` aceita três papéis extras, que o Cyber Arch usa:
`active` (ativo/selecionado), `highlight` (hover) e `alert` (avisos). Nos temas do Omarchy eles
viram o `accent`, o `accent` e o `yellow`.

## Observações

- **Notificações:** nunca aparecem sozinhas na tela; ficam guardadas na central (swaync). O sino
  da Waybar, ao lado da captura de tela, ganha um selo quando chega alguma: clique para abrir,
  botão direito para limpar.
- **Monitores:** as regras do `hyprland.lua` usam a tela do notebook (`eDP-1`) e dois monitores
  externos identificados pelo modelo. Os workspaces 1–5 ficam no `eDP-1`; num PC de mesa (sem
  essa saída), o `~/.config/hypr/workspaces.lua` os põe no primeiro monitor conectado, e só a
  seção de monitores pode precisar de ajuste.
- **Fora do pacman:** Claude Code (instalador oficial), TeamSpeak 6 (tar.xz do site),
  LocalSend e Insomnia (Flatpak, instalados pelo script).
- **Sem segredos:** tokens, senhas, `.git-credentials` e `.env` nunca entram no repositório.
  Depois de clonar, faça os logins de novo (`gh auth login`, Forgejo, Codex, Tailscale).
