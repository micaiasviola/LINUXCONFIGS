# Prompt de inicialização máxima — Claude Code monta o ambiente Hyprland

Este arquivo tem **duas partes**:

1. **Como usar** (leia você) — quando e onde colar o prompt.
2. **O PROMPT** — tudo entre os marcadores `==== INÍCIO DO PROMPT ====` e `==== FIM DO PROMPT ====`.
   Copie esse bloco inteiro e cole como a **primeira mensagem** para o Claude Code.

---

## 1. Como usar

**Quando rodar:** *depois* de já ter feito a instalação **base** do Arch (a Parte 1 do guia:
particionamento, `pacstrap`, `systemd-boot`, usuário com sudo) e ter reiniciado para dentro do sistema
novo. Ou seja, você está logado como seu usuário, no console (TTY), com **internet funcionando**. A
instalação base é destrutiva/interativa e é melhor feita na mão; deste ponto em diante o Claude Code
assume.

**Bootstrap (instalar o Claude Code no Arch novo):**

```bash
sudo pacman -Syu --needed nodejs npm git base-devel
sudo npm install -g @anthropic-ai/claude-code
cd ~
claude
```

Na primeira execução ele pede login. Depois, **cole o prompt abaixo**. Autorize as ações quando ele
pedir (haverá `sudo` para instalar pacotes e builds do AUR).

**Contexto que o prompt já assume (ajuste se for diferente):**

- Você está numa **VM VMware Workstation** (host Windows) *por enquanto* — o prompt aplica os ajustes
  de VM e deixa um caminho pronto pra migrar ao bare metal.
- No bare metal você usa **3 monitores** — o prompt inclui a configuração multi-monitor e instrui o
  Claude Code a detectar os nomes reais das telas.

**⚠️ Preencha os 3 campos marcados `<<< PREENCHA >>>`** no topo do prompt (nome/e-mail do Git e layout
de teclado) antes de colar. O resto o Claude Code resolve.

---

## 2. O PROMPT

Copie de `==== INÍCIO DO PROMPT ====` até `==== FIM DO PROMPT ====`.

==== INÍCIO DO PROMPT ====

# Papel

Você é o Claude Code operando dentro de uma instalação **limpa** do Arch Linux (sistema base já
instalado, `systemd-boot`, NetworkManager, usuário comum com sudo, UEFI). Sua missão é transformar
esta base num **ambiente de desenvolvimento completo com Hyprland**, o mais próximo possível de um
resultado final polido, criando **todos os arquivos de configuração de uma vez** e deixando tudo
versionado. Trabalhe de forma autônoma, mas **peça confirmação antes de qualquer passo destrutivo**
e antes de rodar lotes de instalação com sudo.

# Dados que eu forneço (PREENCHA)

- Nome do Git: `<<< PREENCHA: Seu Nome >>>`
- E-mail do Git: `<<< PREENCHA: voce@exemplo.com >>>`
- Layout de teclado: `<<< PREENCHA: br  (use "us" se seu teclado for US) >>>`

# Contexto do hardware

- **Agora:** rodando numa **VM (VMware Workstation, host Windows)**. Aplique os ajustes de VM.
- **Depois:** vou migrar para **bare metal com 3 monitores**. Deixe a configuração multi-monitor
  pronta e claramente documentada para ativar na máquina real.

# REGRAS DE OURO (siga à risca)

1. **Alinhamento com a wiki ATUAL (prioridade máxima).** Antes de escrever qualquer configuração do
   Hyprland ou instalar o ecossistema, **consulte as páginas atuais** e siga a sintaxe delas se
   divergir do que descrevo aqui (o Hyprland muda opções entre versões — ex.: backend `aquamarine`,
   seção `shadow`, variáveis de cursor). Fontes a verificar:
   - https://wiki.hypr.land/Getting-Started/Installation/
   - https://wiki.hypr.land/Configuring/Variables/
   - https://wiki.hypr.land/Configuring/Monitors/
   - https://wiki.hypr.land/Configuring/Master-Layout/ e /Dwindle-Layout/
   - https://wiki.hypr.land/Configuring/Advanced-and-Cool/Virtual-GPU/ (ajustes de VM)
   - https://wiki.archlinux.org/title/Hyprland
   Rode `hyprland --version` (ou `pacman -Si hyprland`) para saber a versão instalada e casar a
   sintaxe. **Se algo que eu escrevi estiver desatualizado, corrija e me avise em uma linha o que mudou.**
2. **Não destrua nada em silêncio.** Se um arquivo de config já existir, faça backup em `<arquivo>.bak`
   antes de sobrescrever. Mostre o plano de instalação de pacotes antes de executar.
3. **Detecte o ambiente e adapte.** Use `systemd-detect-virt` para saber se é VM, e `lspci -k | grep -A2 -i vga`
   para a GPU. Aplique os ajustes conforme. Como agora é VM, aplique o perfil de VM e deixe o perfil de
   bare metal comentado/documentado.
4. **Jogos: só os arquivos, não a instalação pesada (estou em VM).** Crie as regras de janela do Steam
   na config do Hyprland, mas **não** instale drivers 32-bit/Steam agora. Em vez disso, gere um script
   `~/dotfiles/scripts/bare-metal-gaming.sh` pronto pra eu rodar depois da migração. Explique isso.
5. **Use `paru`** como helper de AUR (instale-o se não existir). Agrupe instalações por categoria.
6. **Tudo vira dotfiles.** Organize as configs em `~/dotfiles/` com **GNU Stow**, inicialize um repo
   git, faça commits com mensagens claras e gere as listas de pacotes. Este é o entregável que vai
   migrar pro bare metal.
7. **Idempotência e clareza.** Comente as configs. Ao final, rode verificações e me entregue um resumo
   objetivo + próximos passos (como subir o Hyprland, o que trocar no bare metal).

# PASSO A PASSO ESPERADO

**Etapa 0 — Sanity checks.** `whoami`, confirmar sudo, `ping -c2 archlinux.org`, `systemd-detect-virt`,
GPU. Rode `sudo pacman -Syu`. Se faltar algo básico (git, base-devel), instale.

**Etapa 1 — Verificar a wiki.** Faça as consultas da Regra 1 e me dê um resumo curto de qualquer
diferença de sintaxe relevante em relação a este prompt. Só então prossiga.

**Etapa 2 — multilib.** Descomente `[multilib]` em `/etc/pacman.conf` (necessário depois pro Steam) e
`sudo pacman -Syu`.

**Etapa 3 — paru.** Se `command -v paru` falhar, faça build via `git clone https://aur.archlinux.org/paru.git`
+ `makepkg -si`.

**Etapa 4 — Pacotes.** Instale (confirme comigo a lista primeiro):

- **Áudio/base gráfica:** `pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber polkit`
- **Hyprland + ecossistema:** `hyprland hyprpaper hyprlock hypridle hyprpicker hyprpolkitagent
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland`
- **Utilitários de sessão:** `waybar wofi swaync kitty wl-clipboard cliphist grim slurp thunar
  thunar-volman gvfs brightnessctl playerctl pavucontrol network-manager-applet`
- **Fontes:** `ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts noto-fonts-emoji ttf-font-awesome`
- **Shell/CLI:** `zsh starship ripgrep fd bat eza fzf zoxide tmux lazygit git-delta fastfetch btop
  unzip wget curl jq`
- **Dev:** `git github-cli fnm pyenv uv docker docker-compose docker-buildx visual-studio-code-bin`
- **Tema:** `catppuccin-gtk-theme-mocha papirus-icon-theme catppuccin-cursors-mocha nwg-look qt6ct kvantum`
- **Login (opcional, me pergunte):** `sddm`

**Etapa 5 — Estrutura de dotfiles + arquivos de config.** Crie `~/dotfiles/` com subpastas por
"pacote" Stow (espelhando o caminho a partir de `$HOME`), por exemplo
`~/dotfiles/hypr/.config/hypr/…`. Gere os arquivos das seções abaixo (**ESPECIFICAÇÃO DOS ARQUIVOS**).

**Etapa 6 — Aplicar Stow.** `cd ~/dotfiles && stow hypr waybar wofi swaync kitty zsh starship`
(crie os symlinks; faça backup do que já existir no home antes).

**Etapa 7 — Ambiente de dev.**
- `fnm`: adicionar `eval "$(fnm env --use-on-cd)"` ao `.zshrc`; instalar a LTS (`fnm install --lts`);
  `corepack enable`.
- `pyenv` + `uv`: bloco do pyenv no `.zshrc`; `pyenv install 3.12 && pyenv global 3.12`.
- `docker`: `sudo systemctl enable --now docker.service`; `sudo usermod -aG docker $USER` (avise que
  preciso relogar).
- `git`: aplicar `user.name`/`user.email` que forneci, `init.defaultBranch main`, `core.pager delta`,
  diff filter delta. Gerar chave SSH `ed25519` e me instruir a rodar `gh auth login` e subir a chave.

**Etapa 8 — Jogos (só arquivos).** Regras de janela do Steam no `hyprland.conf` (abaixo) + o script
`bare-metal-gaming.sh` (conteúdo abaixo). **Sem instalar** Steam/drivers agora.

**Etapa 9 — Multi-monitor.** Crie `~/.config/hypr/monitors.conf` com o perfil de VM ativo e o perfil de
**3 monitores** comentado, com instruções (abaixo). O `hyprland.conf` deve dar `source` nesse arquivo.

**Etapa 10 — Versionar.** `git init -b main` em `~/dotfiles`, `.gitignore` sensato, commit inicial,
gerar `pkglist-oficial.txt` (`pacman -Qqen`) e `pkglist-aur.txt` (`pacman -Qqem`), commitar. Ofereça
criar o repo remoto com `gh repo create dotfiles --private --source=. --push` (me pergunte antes).

**Etapa 11 — Verificação + resumo.** Rode `hyprland --version`, `hyprctl version` (se possível),
confira que os symlinks existem, `systemctl --user status` para serviços do usuário. Me entregue:
(a) o que foi instalado, (b) diferenças que você encontrou vs. a wiki, (c) como subir o Hyprland,
(d) checklist do que trocar no bare metal (drivers reais, 3 monitores, jogos, remover ajustes de VM).

# ESPECIFICAÇÃO DOS ARQUIVOS

> Use o conteúdo abaixo como **alvo**, mas valide cada opção contra a wiki atual e complete o que
> faltar. Paleta: **Catppuccin Mocha**. Fonte: **JetBrainsMono Nerd Font**.

## `~/.config/hypr/hyprland.conf`

```ini
# Fonte da config multi-monitor (perfil VM x 3 monitores mora aqui):
source = ~/.config/hypr/monitors.conf

################  AJUSTES DE VM (remover/ajustar no bare metal)  ################
cursor {
    no_hardware_cursors = true      # essencial em VM (evita cursor invisível/tela preta)
}
# Descomente SÓ se o Hyprland não subir por falta de aceleração 3D na VM:
# env = LIBGL_ALWAYS_SOFTWARE,1
# env = WLR_RENDERER_ALLOW_SOFTWARE,1

################  PROGRAMAS  ################
$terminal = kitty
$menu = wofi --show drun
$fileManager = thunar
$mainMod = SUPER

################  AUTOSTART  ################
exec-once = waybar & hyprpaper & swaync
exec-once = systemctl --user start hyprpolkitagent
exec-once = hypridle
exec-once = nm-applet --indicator
exec-once = wl-paste --watch cliphist store

env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct

general {
    gaps_in = 5
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(89b4faee) rgba(cba6f7ee) 45deg
    col.inactive_border = rgba(45475aaa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur { enabled = true, size = 5, passes = 2 }
    shadow { enabled = false }     # ligar no bare metal
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, myBezier
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, default
}

dwindle { pseudotile = true, preserve_split = true }

input {
    kb_layout = COLOQUE_O_LAYOUT     # br ou us conforme o campo PREENCHA
    follow_mouse = 1
    touchpad { natural_scroll = true }
}

misc {
    vrr = 1        # útil no bare metal; inócuo na VM
}

################  ATALHOS  ################
bind = $mainMod, Return, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, R, exec, $menu
bind = $mainMod, V, togglefloating,
bind = $mainMod, F, fullscreen,
bind = $mainMod, J, togglesplit,
bind = $mainMod, L, exec, hyprlock
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

# Foco entre janelas
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Foco/mover ENTRE MONITORES (essencial pros 3 monitores)
bind = $mainMod CTRL, left, focusmonitor, l
bind = $mainMod CTRL, right, focusmonitor, r
bind = $mainMod CTRL SHIFT, left, movewindow, mon:l
bind = $mainMod CTRL SHIFT, right, movewindow, mon:r

# Workspaces 1–10 e mover janela
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

################  REGRAS DE JANELA — STEAM/JOGOS  ################
windowrulev2 = float, class:^(steam)$, title:^(Friends List)$
windowrulev2 = float, class:^(steam)$, title:^(Steam Settings)$
windowrulev2 = fullscreen, class:^(gamescope)$
windowrulev2 = immediate, class:^(steam_app_).*$
```

## `~/.config/hypr/monitors.conf`  (o coração do multi-monitor)

```ini
############################################################
# PERFIL ATIVO: VM (1 tela virtual). NÃO mexer enquanto na VM.
############################################################
monitor = , preferred, auto, 1

############################################################
# PERFIL BARE METAL — 3 MONITORES  (DESCOMENTAR na máquina real)
#
# COMO PREENCHER:
#   1) Rode:  hyprctl monitors all
#   2) Anote o NOME (ex.: DP-1, DP-2, HDMI-A-1), resolução@refresh e a ordem física.
#   3) A sintaxe é:  monitor = NOME, RESOLUÇÃO@HZ, POSIÇÃO_X x Y, ESCALA
#      A POSIÇÃO define o arranjo lado a lado. Ex.: três telas 1080p em linha:
#      esquerda começa em 0x0, central em 1920x0, direita em 3840x0.
#
# Exemplo (AJUSTE nomes/resoluções aos SEUS monitores):
# monitor = DP-1,   1920x1080@144, 0x0,    1     # esquerda
# monitor = DP-2,   2560x1440@144, 1920x0, 1     # centro (principal)
# monitor = HDMI-A-1, 1920x1080@60, 4480x0, 1    # direita
#
# Definir o monitor principal (onde abrem novas janelas por padrão):
# Prefira ancorar workspaces a cada tela para um fluxo previsível:
# workspace = 1, monitor:DP-2, default:true
# workspace = 2, monitor:DP-2
# workspace = 3, monitor:DP-2
# workspace = 4, monitor:DP-1
# workspace = 5, monitor:DP-1
# workspace = 6, monitor:HDMI-A-1
# workspace = 7, monitor:HDMI-A-1
#
# Dica: se uma tela estiver na vertical, adicione 'transform,1' (90°) ou 3 (270°) no fim:
# monitor = HDMI-A-1, 1920x1080@60, 4480x0, 1, transform, 1
############################################################
```

> Claude Code: no bare metal, ofereça rodar `hyprctl monitors all`, me pergunte a **ordem física**
> (qual é esquerda/centro/direita) e o **monitor principal**, e então **gere automaticamente** este
> arquivo já preenchido, comentando o perfil de VM.

## `~/.config/hypr/hyprpaper.conf`

```ini
preload = ~/.config/hypr/wall.jpg
wallpaper = , ~/.config/hypr/wall.jpg
splash = false
```

(Baixe/coloque um `wall.jpg`. No bare metal com 3 telas, defina `wallpaper = NOME, ~/.config/hypr/wall.jpg`
para cada monitor, ou use `wallpaper = , caminho` para aplicar em todas.)

## `~/.config/hypr/hypridle.conf`

```ini
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
listener { timeout = 300, on-timeout = loginctl lock-session }
listener { timeout = 330, on-timeout = hyprctl dispatch dpms off, on-resume = hyprctl dispatch dpms on }
```

## `~/.config/hypr/hyprlock.conf`
Gere uma tela de bloqueio **Catppuccin Mocha** simples e funcional (fundo escuro, campo de senha
centralizado, relógio). Valide o formato de `hyprlock` na wiki, pois ele tem sintaxe própria.

## Waybar — `~/.config/waybar/config.jsonc` e `style.css`
Gere uma barra **completa e Catppuccin**: workspaces do Hyprland, janela ativa, e à direita
relógio, rede (nm-applet), áudio (pulseaudio/wireplumber), CPU/mem, bateria (só se existir). **Importante
para 3 monitores:** configure a Waybar para aparecer em **todas as telas** (o campo `"output"` ausente
ou listando os monitores). Fonte `JetBrainsMono Nerd Font`. Ícones via font-awesome/nerd font.

## Wofi — `~/.config/wofi/style.css`
Launcher Catppuccin, cantos arredondados, coerente com a barra.

## SwayNC — `~/.config/swaync/config.json` e `style.css`
Central de notificações Catppuccin.

## Kitty — `~/.config/kitty/kitty.conf`
Tema Catppuccin Mocha, fonte `JetBrainsMono Nerd Font` 11, `background_opacity 0.95`, padding.

## `~/.config/starship.toml`
Prompt informativo: diretório, branch/status git, versões de node/python ativas, venv, duração de
comando. Estética Catppuccin.

## `~/.zshrc`
```bash
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)
eval "$(fnm env --use-on-cd)"

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git'
alias cat='bat'
alias lg='lazygit'
```
Depois rode `chsh -s /usr/bin/zsh`.

## `~/dotfiles/scripts/bare-metal-gaming.sh`  (rodar SÓ após migrar pro hardware real)
```bash
#!/usr/bin/env bash
set -euo pipefail
echo ">> Gaming setup — rode isto NO BARE METAL, não na VM."

# 1) Detectar GPU e instalar drivers 32-bit corretos:
if lspci | grep -qi 'nvidia'; then
    paru -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils
elif lspci | grep -qi 'amd\|radeon'; then
    paru -S --needed mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
else
    paru -S --needed mesa lib32-mesa vulkan-intel lib32-vulkan-intel
fi

# 2) Steam + ferramentas:
paru -S --needed steam gamemode lib32-gamemode gamescope mangohud lib32-mangohud protonup-qt

echo ">> Feito. No Steam: Settings > Compatibility > Enable Steam Play for all titles."
echo ">> Launch options sugerida: gamemoderun gamescope -W 2560 -H 1440 -r 144 -f -- %command%"
```
Torne executável (`chmod +x`).

# AJUSTES VM → BARE METAL (documente isto no resumo final)

- `monitors.conf`: comentar o perfil VM, descomentar/gerar o perfil dos 3 monitores reais.
- `hyprland.conf`: `cursor.no_hardware_cursors` pode voltar a `false`; **remover** os `env` de software
  render; `decoration.shadow.enabled = true`.
- Instalar o **driver de vídeo real** (o `bare-metal-gaming.sh` já cobre a parte 32-bit; para o desktop,
  garanta `mesa` + vulkan da GPU; NVIDIA exige ajustes extras de Wayland — consulte a wiki Hyprland/NVIDIA).
- Rodar `bare-metal-gaming.sh`.
- Reaplicar dotfiles via `stow` e reinstalar pacotes via `pkglist-*.txt`.

# ENTREGA FINAL
Ao terminar, me dê um resumo curto (sem despejar logs): o que instalou, diferenças vs. wiki, como subir
o Hyprland (via `Hyprland` no TTY ou SDDM), e o checklist de bare metal. Confirme que `~/dotfiles` está
commitado.

==== FIM DO PROMPT ====

---

## 3. Observações finais (para você, não faz parte do prompt)

- **Por que "verificar a wiki" está no topo:** o Hyprland troca nomes de opções entre versões (o backend
  virou `aquamarine`, a seção de sombra virou `shadow { }`, variáveis de cursor mudaram). Como o Claude
  Code roda com acesso à web, mandar ele conferir a wiki na hora é o que mantém o resultado "alinhado
  com a wiki atual" mesmo daqui a meses.
- **Na VM você chega perto do final, menos o desempenho gráfico e os jogos** — isso é esperado. O prompt
  já separa o que é bare metal (3 monitores reais, drivers, Steam) num caminho pronto.
- **Este prompt é o "gêmeo executável" do guia** `guia-arch-hyprland-dev.md`. O guia explica o porquê;
  o prompt manda fazer. Mantenha os dois juntos no seu repo de dotfiles.
