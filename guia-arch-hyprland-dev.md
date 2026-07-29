# Arch Linux + Hyprland para Desenvolvimento — Plano e Guia Passo a Passo

> Objetivo: montar um ambiente Linux **100% do zero** (Arch puro + Hyprland configurado na mão),
> primeiro numa **máquina virtual** para aprender e construir a personalização, e depois **migrar para o
> disco físico real** reaproveitando os dotfiles. Uso principal: desenvolvimento (VS Code, Git/GitHub,
> Node, Python, terminal), **PostgreSQL** e **Docker**, além de Chrome/Edge e serviços Microsoft via web/PWA.
>
> Perfil assumido: desenvolvedor confortável em aprender qualquer coisa. Por isso o guia não "mastiga"
> demais — explica o *porquê* de cada escolha e assume que você lê mensagem de erro e corre atrás.

---

## Sumário

1. [Filosofia do plano (a arquitetura)](#1-filosofia-do-plano-a-arquitetura)
2. [Aviso importante: Hyprland dentro de VM com host Windows](#2-aviso-importante-hyprland-dentro-de-vm-com-host-windows)
3. [Parte 0 — Preparar a máquina virtual](#3-parte-0--preparar-a-máquina-virtual)
4. [Parte 1 — Instalação manual do Arch](#4-parte-1--instalação-manual-do-arch)
5. [Parte 2 — Pós-instalação (rede, áudio, AUR)](#5-parte-2--pós-instalação-rede-áudio-aur)
6. [Parte 3 — Hyprland do zero](#6-parte-3--hyprland-do-zero)
7. [Parte 4 — Ambiente de desenvolvimento](#7-parte-4--ambiente-de-desenvolvimento)
8. [Parte 5 — Jogos com Steam](#8-parte-5--jogos-com-steam)
9. [Parte 6 — Personalização (temas, fontes, ícones)](#9-parte-6--personalização-temas-fontes-ícones)
10. [Parte 7 — Dotfiles: versionar tudo](#10-parte-7--dotfiles-versionar-tudo)
11. [Parte 8 — Migração da VM para o bare metal](#11-parte-8--migração-da-vm-para-o-bare-metal)
12. [Apêndice — Troubleshooting comum](#12-apêndice--troubleshooting-comum)

---

## 1. Filosofia do plano (a arquitetura)

A ideia central que amarra tudo: **a máquina não é a configuração**. A sua configuração são os
**arquivos de texto** (dotfiles) + a **lista de pacotes**. Se você tratar isso como um projeto de
código — versionado no Git — então "migrar para o disco real" deixa de ser "copiar um HD" e passa a
ser "instalar Arch limpo e dar `git clone`". É mais rápido, mais limpo e reproduzível quantas vezes
quiser.

Camadas do sistema, de baixo pra cima:

| Camada | Escolha | Por quê |
|---|---|---|
| **Boot** | `systemd-boot` (UEFI) | Simples, sem GRUB; nativo do systemd que o Arch já usa. |
| **Base** | Arch + `linux` (ou `linux-lts` de reserva) | Rolling release, pacotes novos, AUR gigante. |
| **Rede** | NetworkManager | Funciona no fio e no Wi‑Fi, integra com applet gráfico. |
| **Áudio** | PipeWire + WirePlumber | Padrão atual, substitui PulseAudio/JACK. |
| **Sessão gráfica** | Wayland + **Hyprland** | Tiling dinâmico, animações, altíssima customização. |
| **Barra / launcher / notif.** | Waybar + Wofi (ou Rofi) + SwayNC (ou Mako) | Peças modulares que você escolhe e troca. |
| **Terminal** | Kitty (ou Alacritty/Foot) | GPU‑accelerated, é o default que o Hyprland já sugere. |
| **Shell** | Zsh + Starship | Autocomplete bom + prompt informativo (git, venv, etc.). |
| **Dev** | fnm (Node), pyenv/uv (Python), Docker, PostgreSQL, gh | Versionadores por linguagem + containers pra isolar serviços. |
| **Config** | dotfiles em Git + GNU Stow | Reproduzível; a "alma" da máquina mora aqui. |

Regra de ouro do consumo de RAM (você tem 24 GB, então sobra folga, mas vale a filosofia):
o Hyprland ocioso fica em ~0,5–0,8 GB. Quem come memória é **Chrome/Edge e apps Electron**
(VS Code, Teams PWA). Ou seja, leveza real = base enxuta + disciplina com abas, não "otimizar o WM".

---

## 2. Aviso importante: Hyprland dentro de VM com host Windows

Isto aqui vai te poupar horas de frustração, então leia com atenção.

O Hyprland **exige aceleração de GPU (OpenGL/EGL)**. Máquinas virtuais são justamente fracas nisso,
e no **host Windows** o cenário é o mais limitado:

- **VirtualBox** → o pior caso. Suporte a Wayland/3D ruim; Hyprland costuma dar tela preta ou travar. **Evite.**
- **QEMU no Windows** → sem KVM (isso é só no host Linux). Usa o acelerador WHPX pra CPU, mas a
  aceleração 3D de GPU (virtio‑gpu venus/virgl) no host Windows é experimental/limitada. Resultado:
  Hyprland cai em renderização por software (lento).
- **VMware Workstation Pro** → **melhor opção prática no Windows.** Ficou **gratuito** para uso pessoal
  (e depois também comercial). Tem aceleração 3D própria; com ela ligada + um ajuste no Hyprland
  (desligar cursor de hardware) normalmente sobe.

**A conclusão honesta:** dentro da VM, no host Windows, o Hyprland vai rodar de "ok" a "meio
travado" — e isso é **esperado e tudo bem**. Trate a VM como um **laboratório**: o objetivo dela é
(1) você aprender a instalação do Arch sem risco de detonar o Windows, e (2) construir e testar seus
**dotfiles**. A fluidez de verdade (animações lisas) só vem no **bare metal**, onde a GPU é real.

> Se em algum momento a VM te frustrar demais graficamente, um caminho alternativo é pular direto pro
> **dual boot** no bare metal e usar a VM só pra praticar os passos destrutivos (particionamento).
> Mas dá pra fazer tudo na VM — só ajuste a expectativa.

---

## 3. Parte 0 — Preparar a máquina virtual

**Recomendado:** VMware Workstation Pro (grátis para uso pessoal). Baixe pelo site da Broadcom
(exige criar uma conta gratuita).

Baixe também a **ISO do Arch Linux** em <https://archlinux.org/download/> (pegue um mirror BR, ex.:
UFPR/UFSC/C3SL, ou use o torrent).

Configuração da VM (ajuste ao seu gosto — você tem 24 GB de RAM e NVMe de 500 GB no host):

- **CPU:** 4 vCPUs (ou mais). Marque virtualização aninhada se for rodar Docker/KVM dentro.
- **RAM:** 6–8 GB já é confortável pro laboratório.
- **Disco:** 40–60 GB, tipo NVMe/SSD, provisionamento dinâmico. É suficiente pra Arch + Hyprland + dev.
- **Firmware:** **UEFI** (não BIOS legado). Isso importa pro `systemd-boot`.
- **Aceleração 3D:** **ligada.** Em *Display*, marque "Accelerate 3D graphics" e dê uns 2–4 GB de VRAM.
- **Rede:** NAT (padrão) já resolve.

> **VMware + Wayland — dica de ouro:** se a tela ficar preta ao subir o Hyprland, o culpado quase sempre
> é o *cursor de hardware*. A gente resolve isso na config do Hyprland (Parte 3) com
> `cursor { no_hardware_cursors = true }`. Se ainda assim não subir, cai pro modo software (também na
> Parte 3). Guarde essa informação.

Suba a VM apontando pra ISO do Arch. Você vai cair num shell root (`root@archiso`). Bora instalar.

---

## 4. Parte 1 — Instalação manual do Arch

> Referência canônica sempre atualizada: **Installation guide** da ArchWiki
> (<https://wiki.archlinux.org/title/Installation_guide>). O passo a passo abaixo é o caminho UEFI +
> systemd-boot + NetworkManager, que é o que vamos usar.

### 4.1 Teclado, rede e relógio (ambiente live)

```bash
# Layout de teclado ABNT2 (se for teclado BR). Para US, pule.
loadkeys br-abnt2

# Confirme que bootou em modo UEFI (tem que listar arquivos, não dar erro):
cat /sys/firmware/efi/fw_platform_size   # deve imprimir 64

# Rede: na VM em NAT o cabo já vem conectado. Teste:
ping -c 3 archlinux.org

# Sincronizar o relógio
timedatectl set-ntp true
```

(Se fosse Wi‑Fi no bare metal, usaria `iwctl` — cobrimos na Parte 10.)

### 4.2 Particionamento

Na VM o disco costuma ser `/dev/sda` (ou `/dev/nvme0n1` se você configurou NVMe). Confirme:

```bash
lsblk
```

Vamos usar um esquema simples UEFI: uma partição EFI + uma raiz. (Sem partição swap dedicada —
usaremos **zram** ou swapfile depois; opcional.)

```bash
# Abra o cfdisk (interface de texto, fácil):
cfdisk /dev/sda        # ajuste o device!
```

No `cfdisk`, escolha rótulo **GPT** e crie:

1. **EFI System** — 512 MB (tipo "EFI System")
2. **Linux filesystem** — o resto do disco (raiz `/`)

Grave (`Write` → `yes`) e saia (`Quit`). Ficará algo como `/dev/sda1` (EFI) e `/dev/sda2` (raiz).

Formate e monte:

```bash
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2          # ext4 é simples e robusto; Btrfs é opção avançada (snapshots)

mount /dev/sda2 /mnt
mount --mkdir /dev/sda1 /mnt/boot
```

> Quer Btrfs com snapshots (útil pra reverter atualizações)? Dá, mas adiciona subvolumes e complexidade.
> Para o laboratório, ext4 é o caminho sem pedra. No bare metal você decide se quer Btrfs.

### 4.3 Instalar o sistema base (pacstrap)

```bash
# Atualize os mirrors para servidores rápidos (opcional mas recomendado):
pacman -Sy reflector
reflector --country Brazil --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Instale a base + kernel + firmware + ferramentas essenciais:
pacstrap -K /mnt base linux linux-firmware base-devel \
    networkmanager nano vim git sudo \
    intel-ucode                # use amd-ucode se sua CPU for AMD; na VM pode instalar o correspondente ao host
```

Gere o `fstab`:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab             # confira se ficou coerente
```

### 4.4 Entrar no sistema (chroot) e configurar

```bash
arch-chroot /mnt
```

Fuso, relógio e locale:

```bash
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Habilite os locales que quer, editando /etc/locale.gen (descomente as linhas):
#   en_US.UTF-8 UTF-8
#   pt_BR.UTF-8 UTF-8
nano /etc/locale.gen
locale-gen

echo 'LANG=pt_BR.UTF-8' > /etc/locale.conf     # ou en_US.UTF-8 se preferir sistema em inglês
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf     # teclado no console
```

Hostname:

```bash
echo 'arch-dev' > /etc/hostname
```

Senha do root:

```bash
passwd
```

Seu usuário (troque `seunome`):

```bash
useradd -m -G wheel -s /bin/bash seunome
passwd seunome

# Dê sudo ao grupo wheel: rode `EDITOR=nano visudo` e descomente:
#   %wheel ALL=(ALL:ALL) ALL
EDITOR=nano visudo
```

### 4.5 Bootloader (systemd-boot)

```bash
bootctl install
```

Crie a entrada de boot. Primeiro pegue o **PARTUUID/UUID** da raiz:

```bash
# Anote o UUID da partição raiz (/dev/sda2):
blkid -s UUID -o value /dev/sda2
```

Edite o loader:

```bash
nano /boot/loader/loader.conf
```

Conteúdo:

```
default arch.conf
timeout 3
console-mode max
editor no
```

Crie a entrada `nano /boot/loader/entries/arch.conf`:

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=COLE_O_UUID_AQUI rw
```

> Trocou `intel-ucode` por `amd-ucode`? Ajuste a linha do initrd. A ordem importa: microcode antes do
> initramfs.

### 4.6 Habilitar serviços e finalizar

```bash
systemctl enable NetworkManager

exit                 # sai do chroot
umount -R /mnt
reboot               # remova a ISO da VM ao reiniciar
```

Se tudo deu certo, você inicia no Arch em modo texto e loga com seu usuário. **Base pronta.**

---

## 5. Parte 2 — Pós-instalação (rede, áudio, AUR)

Logado como seu usuário no console.

### 5.1 Confirmar rede e atualizar

```bash
ping -c 3 archlinux.org
sudo pacman -Syu
```

### 5.2 Áudio (PipeWire)

```bash
sudo pacman -S pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
# Os serviços do PipeWire sobem via socket do usuário automaticamente na sessão gráfica.
```

### 5.3 AUR helper (paru)

O AUR é onde mora metade das coisas boas (VS Code oficial, temas, etc.). O `paru` é um helper enxuto:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd .. && rm -rf paru
```

A partir daqui, `paru -S pacote` instala tanto de repositório oficial quanto do AUR.

### 5.4 Fontes básicas + Nerd Font

A Waybar, o prompt Starship e ícones dependem de uma **Nerd Font** (fontes com ícones embutidos):

```bash
sudo pacman -S ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts noto-fonts-emoji ttf-font-awesome
```

---

## 6. Parte 3 — Hyprland do zero

### 6.1 Instalar o Hyprland e o ecossistema

```bash
paru -S hyprland \
    hyprpaper hyprlock hypridle hyprpicker hyprpolkitagent \
    xdg-desktop-portal-hyprland \
    qt5-wayland qt6-wayland \
    kitty \
    waybar wofi swaync \
    wl-clipboard cliphist grim slurp \
    thunar thunar-volman gvfs \
    brightnessctl playerctl pavucontrol \
    network-manager-applet \
    polkit
```

O que é cada peça:

- **hyprland** — o compositor (o coração).
- **hyprpaper / hyprlock / hypridle / hyprpicker** — wallpaper / tela de bloqueio / gerenciador de
  ociosidade / seletor de cor. Ecossistema oficial do próprio Hyprland.
- **hyprpolkitagent** — agente polkit (aquele pop‑up "digite sua senha" de apps gráficos).
- **xdg-desktop-portal-hyprland** — portais (compartilhar tela, seletor de arquivos). Essencial pra
  Chrome/Edge/Teams compartilharem tela e abrirem diálogos direito.
- **waybar** — barra de status. **wofi** — launcher (menu de apps). **swaync** — central de notificações.
- **grim + slurp** — screenshot (capturar região). **cliphist** — histórico de clipboard.
- **thunar** — gerenciador de arquivos gráfico (o "Explorer").

### 6.2 Subir o Hyprland

Por enquanto, suba manualmente pra testar. Do console (TTY):

```bash
Hyprland
```

Na **primeira vez** o Hyprland cria `~/.config/hypr/hyprland.conf` com um exemplo padrão. Se der
**tela preta na VM**, não entre em pânico — é o cursor de hardware. Volte pro TTY (`Ctrl+Alt+F2`,
logue, edite a config abaixo) ou já deixe a config pronta antes de subir.

### 6.3 Configuração mínima e funcional

Edite `~/.config/hypr/hyprland.conf`. Abaixo um ponto de partida **enxuto e comentado**. Ajuste
`$mainMod`, teclado e monitores ao seu gosto.

```ini
# ~/.config/hypr/hyprland.conf

################  MONITOR  ################
# Deixe 'preferred' na VM; no bare metal você especifica resolução/refresh.
monitor = , preferred, auto, 1

################  AJUSTES DE VM  ################
# ESSENCIAL para VM (VMware/QEMU/VBox): desliga o cursor de hardware (causa da tela preta).
cursor {
    no_hardware_cursors = true
}
# Se AINDA assim não subir na VM (sem aceleração 3D), force render por software
# descomentando as linhas abaixo. No bare metal, mantenha COMENTADO (senão fica lento à toa).
# env = LIBGL_ALWAYS_SOFTWARE,1
# env = WLR_RENDERER_ALLOW_SOFTWARE,1

################  PROGRAMAS PADRÃO  ################
$terminal = kitty
$menu = wofi --show drun
$fileManager = thunar

################  AUTOSTART  ################
exec-once = waybar & hyprpaper & swaync
exec-once = systemctl --user start hyprpolkitagent
exec-once = hypridle
exec-once = nm-applet --indicator
exec-once = wl-paste --watch cliphist store   # histórico de clipboard

################  VARIÁVEIS DE AMBIENTE  ################
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt6ct

################  VISUAL  ################
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
    blur {
        enabled = true
        size = 5
        passes = 2
    }
    # Sombras deixam mais bonito, mas pesam na VM sem GPU. Ligue no bare metal.
    shadow {
        enabled = false
    }
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, myBezier
    animation = fade, 1, 5, default
    animation = workspaces, 1, 4, default
}

dwindle {
    pseudotile = true
    preserve_split = true
}

input {
    kb_layout = br            # troque para 'us' se seu teclado for US
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

################  ATALHOS (o "controle de janelas" que você quer)  ################
$mainMod = SUPER            # tecla Windows

bind = $mainMod, Return, exec, $terminal
bind = $mainMod, Q, killactive,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, R, exec, $menu
bind = $mainMod, V, togglefloating,
bind = $mainMod, F, fullscreen,
bind = $mainMod, J, togglesplit,
bind = $mainMod, L, exec, hyprlock

# Foco entre janelas (estilo vim: h/j/k/l ou setas)
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces 1–10
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
# Mover a janela ativa para um workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3

# Screenshot de região para a área de transferência
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

# Redimensionar/mover com o mouse + SUPER
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Controle de volume/brilho
binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
```

> As cores acima (azul/roxo/cinza) seguem a paleta **Catppuccin Mocha**, popular e bonita.
> Depois você troca à vontade.

### 6.4 Wallpaper (hyprpaper)

`~/.config/hypr/hyprpaper.conf`:

```ini
preload = ~/.config/hypr/wall.jpg
wallpaper = , ~/.config/hypr/wall.jpg
splash = false
```

Jogue uma imagem em `~/.config/hypr/wall.jpg`.

### 6.5 Lock e idle (hyprlock + hypridle)

`~/.config/hypr/hypridle.conf` (bloqueia após inatividade e apaga a tela):

```ini
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}
listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

O `hyprlock` já funciona com uma config default; personalize em `~/.config/hypr/hyprlock.conf` depois.

### 6.6 Login gráfico (opcional): SDDM

Você pode continuar subindo com `Hyprland` no TTY, mas um **display manager** deixa profissional:

```bash
paru -S sddm
sudo systemctl enable sddm
```

No próximo boot, o SDDM mostra a tela de login e você escolhe a sessão Hyprland.

> **Alternativa sem DM:** subir automaticamente ao logar no TTY1 adicionando ao `~/.zprofile`:
> `[[ $(tty) == /dev/tty1 ]] && exec Hyprland`. Mais minimalista, menos RAM.

---

## 7. Parte 4 — Ambiente de desenvolvimento

Agora o que interessa pro seu dia a dia. Tudo que você faz no Windows, aqui.

### 7.1 Shell moderno: Zsh + Starship + ferramentas de CLI

```bash
paru -S zsh starship \
    ripgrep fd bat eza fzf zoxide \
    tmux lazygit git-delta \
    fastfetch btop unzip wget curl jq

# Troque seu shell para zsh:
chsh -s /usr/bin/zsh
```

Ative o Starship e alguns aliases no `~/.zshrc` (crie/edite):

```bash
# ~/.zshrc
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git'
alias cat='bat'
alias lg='lazygit'
```

O que cada um faz: **ripgrep** (`rg`, grep turbinado), **fd** (find amigável), **bat** (cat com
syntax highlight), **eza** (ls moderno com ícones/git), **fzf** (busca fuzzy interativa), **zoxide**
(cd inteligente — `z projeto` pula pra pasta usada), **lazygit** (TUI de git sensacional),
**delta** (diff bonito no git), **btop** (monitor de sistema), **tmux** (multiplexador de terminal).

### 7.2 Git + GitHub

```bash
paru -S git github-cli

git config --global user.name "Seu Nome"
git config --global user.email "voce@exemplo.com"
git config --global init.defaultBranch main
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"

# Chave SSH para o GitHub:
ssh-keygen -t ed25519 -C "voce@exemplo.com"
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519

# Autentique o gh (ele oferece subir a chave SSH pra você):
gh auth login
```

Assinar commits com SSH (opcional, mostra "Verified" no GitHub):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

### 7.3 VS Code

Você quer o **VS Code oficial da Microsoft** (marketplace completo, não o OSS):

```bash
paru -S visual-studio-code-bin
```

Para rodar bem no Wayland (evita tela borrada/HiDPI torto), force o backend Wayland quando quiser:

```bash
code --enable-features=UseOzonePlatform --ozone-platform=wayland
```

> Se o VS Code ficar com fontes borradas ou travar no Wayland dentro da VM, rode em modo XWayland
> (padrão, sem as flags acima). No bare metal, o Wayland nativo costuma ficar ótimo.

### 7.4 Node.js (via fnm — versionador)

Não instale Node do pacman (prende numa versão). Use **fnm** (rápido, escrito em Rust):

```bash
paru -S fnm
# Adicione ao ~/.zshrc:
echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
# Recarregue o shell e instale a LTS:
exec zsh
fnm install --lts
fnm use lts-latest
node -v && npm -v

# Corepack habilita pnpm/yarn na hora:
corepack enable
```

### 7.5 Python (via pyenv + uv)

Python do sistema existe, mas pra projetos use versionador. Combinação moderna: **pyenv** (versões do
interpretador) + **uv** (gerenciador de pacotes/venv absurdamente rápido, da Astral):

```bash
paru -S pyenv uv
# pyenv no ~/.zshrc:
cat >> ~/.zshrc <<'EOF'
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
EOF
exec zsh

# Instalar uma versão e definir global:
pyenv install 3.12
pyenv global 3.12

# Fluxo por projeto com uv (cria venv e resolve deps num piscar):
#   uv init meu-projeto && cd meu-projeto
#   uv add requests
#   uv run main.py

# Ferramentas Python isoladas (estilo pipx) também via uv:
#   uv tool install ruff
```

### 7.6 Docker

Roda **nativo** no Arch (é Linux de verdade — sem a camada do Docker Desktop do Windows):

```bash
paru -S docker docker-compose docker-buildx
sudo systemctl enable --now docker.service

# Rodar docker sem sudo: adicione seu usuário ao grupo e RELOGUE:
sudo usermod -aG docker $USER
# (faça logout/login ou reboot para o grupo valer)

docker run --rm hello-world     # teste após relogar
```

> Alternativa sem daemon root: **Podman** (`paru -S podman podman-compose`), rootless por padrão.
> Mas como você pediu Docker, seguimos com ele. TUI útil: `paru -S lazydocker`.

### 7.7 PostgreSQL

Como você escolheu **Postgres + Docker**, a recomendação é rodar o Postgres **em container** (isola
versões por projeto, não polui o sistema). Mostro as duas estratégias.

**Opção A — Postgres via Docker (recomendada para dev):**

```bash
# Um Postgres descartável para desenvolvimento:
docker run -d --name pg-dev \
  -e POSTGRES_PASSWORD=dev \
  -e POSTGRES_USER=dev \
  -e POSTGRES_DB=devdb \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  postgres:16
```

Ou, melhor ainda, um `docker-compose.yml` por projeto:

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: devdb
    ports: ["5432:5432"]
    volumes: ["pgdata:/var/lib/postgresql/data"]
volumes:
  pgdata:
```

Sobe com `docker compose up -d`.

**Opção B — Postgres nativo (instalado no sistema):**

```bash
paru -S postgresql
sudo -iu postgres initdb -D /var/lib/postgres/data
sudo systemctl enable --now postgresql
sudo -iu postgres createuser --interactive   # crie seu usuário
sudo -iu postgres createdb devdb
```

**Clientes (CLI e GUI):**

```bash
paru -S postgresql-libs   # traz o psql (cliente de linha de comando)
paru -S pgcli             # CLI turbinado: autocomplete + syntax highlight
paru -S dbeaver           # GUI completa (opcional). Alternativa: beekeeper-studio-bin
```

Conectar via CLI:

```bash
psql -h localhost -U dev -d devdb          # senha: dev (no exemplo do container)
# ou o pgcli, mais agradável:
pgcli -h localhost -U dev devdb
```

### 7.8 Navegadores e serviços Microsoft

```bash
paru -S google-chrome                 # (AUR) — ou 'chromium' dos repos oficiais
paru -S microsoft-edge-stable-bin     # (AUR) Edge nativo, ótimo pra login corporativo/Entra ID
```

Serviços Microsoft no Linux, na prática: **Office** roda no navegador (office.com); **Teams** virou
**PWA** (abra no Edge/Chrome e "Instalar app"); **Outlook** via web ou o app PWA; **OneDrive** não tem
cliente oficial — use `paru -S onedrive-abraunegg` (cliente da comunidade, via CLI/systemd) se precisar
sincronizar. Login corporativo (Entra ID/Intune) funciona melhor no **Edge**.

> **Wayland nos navegadores:** Chrome/Edge recentes rodam em Wayland nativo. Se a fonte sair borrada,
> ligue em `chrome://flags` → "Preferred Ozone platform" = **Wayland**.

---

## 8. Parte 5 — Jogos com Steam

Boa notícia: jogar no Linux amadureceu absurdamente (obrigado, Steam Deck). A **Proton** roda a maioria
dos jogos de Windows sem você fazer nada — muitos ficam iguais ou até mais rápidos que no Windows.

> ⚠️ **Isto é etapa de bare metal, não de VM.** Jogo precisa de GPU real. Dentro da VM no host Windows
> não há aceleração 3D suficiente — Steam até abre, mas jogo praticamente não roda. Instale e configure
> Steam **na máquina real** (Parte 8). Deixei a seção aqui no fluxo por ser "categoria de software",
> mas execute-a só depois de estar no hardware.

### 8.1 Pré-requisito: habilitar o repositório `multilib`

Steam e as bibliotecas 32‑bit vivem no repositório **multilib**, que vem desligado por padrão. Edite
`/etc/pacman.conf` e **descomente** as duas linhas:

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Depois atualize:

```bash
sudo pacman -Syu
```

### 8.2 Drivers de GPU com as bibliotecas 32‑bit

A Proton precisa das versões **32‑bit (`lib32-*`)** dos drivers Vulkan. Instale conforme a sua GPU
**real**:

```bash
# AMD (Radeon):
paru -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon

# Intel (Arc / integrada):
paru -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel

# NVIDIA:
paru -S nvidia-dkms nvidia-utils lib32-nvidia-utils
```

### 8.3 Instalar o Steam e as ferramentas de jogo

```bash
paru -S steam \
    gamemode lib32-gamemode \
    gamescope \
    mangohud lib32-mangohud
```

- **gamemode** — otimiza CPU/governor automaticamente enquanto o jogo roda.
- **gamescope** — um "micro‑compositor" da Valve (o mesmo do Steam Deck). No Hyprland ele resolve a
  maioria das dores de tela cheia, escala e VRR — rode os jogos dentro dele.
- **mangohud** — overlay de FPS/CPU/GPU/temperatura (aquele HUD no canto).

Ao abrir o Steam pela primeira vez ele baixa uns runtimes; deixe terminar.

### 8.4 Proton (rodar jogos de Windows)

No Steam: **Settings → Compatibility → marque "Enable Steam Play for all other titles"** e selecione a
Proton mais recente (ou "Proton Experimental"). Isso libera rodar praticamente todo o catálogo Windows.

Para versões turbinadas da comunidade (**Proton‑GE**, que conserta jogos específicos), o jeito fácil é
o **ProtonUp‑Qt**:

```bash
paru -S protonup-qt
```

Abra, escolha "Add version", instale o **GE‑Proton** mais novo e depois selecione ele nas propriedades
do jogo (**Properties → Compatibility → Force a specific Steam Play tool**).

> **Verificar se um jogo roda:** consulte o **ProtonDB** (<https://www.protondb.com>). Para jogos
> multiplayer com anti‑cheat "de kernel" (EAC/BattlEye), confira o **areweanticheatyet.com** — alguns
> funcionam, outros são bloqueados pelo desenvolvedor no Linux. É a única categoria com asterisco.

### 8.5 Hyprland + Steam: ajustes que evitam dor de cabeça

O Steam tem janelinhas tortas (lista de amigos, notificações) e jogos em tela cheia às vezes brigam com
o tiling. Adicione **regras de janela** ao `~/.config/hypr/hyprland.conf`:

```ini
# Steam: deixa as janelas auxiliares flutuando e some com bordas em jogo
windowrulev2 = float, class:^(steam)$, title:^(Friends List)$
windowrulev2 = float, class:^(steam)$, title:^(Steam Settings)$
# Jogos: tela cheia sem bordas/gaps
windowrulev2 = fullscreen, class:^(gamescope)$
windowrulev2 = immediate, class:^(steam_app_).*$    # reduz input lag em jogos

# VRR (FreeSync/G-Sync) — só faz efeito no bare metal com monitor compatível
misc {
    vrr = 1
}
```

A forma recomendada de rodar cada jogo é **dentro do gamescope + gamemode**. Nas *Launch Options* do
jogo (Properties → General → Launch Options), use algo como:

```
gamemoderun gamescope -W 2560 -H 1440 -r 144 -f -- %command%
```

(ajuste largura `-W`, altura `-H` e refresh `-r` ao seu monitor). Para ver o HUD, acrescente MangoHud:

```
mangohud gamemoderun gamescope -W 1920 -H 1080 -f -- %command%
```

### 8.6 Controle (gamepad)

O **Steam Input** já reconhece a maioria dos controles (Xbox, PlayStation, 8BitDo) via USB
automaticamente. Para **Xbox sem fio via Bluetooth** com rumble melhor:

```bash
paru -S xpadneo-dkms      # driver melhorado para controles Xbox One/Series por BT
```

Para o **dongle wireless oficial da Xbox**: `paru -S xone-dkms`. PlayStation (DualShock/DualSense)
funciona nativo no kernel.

### 8.7 Loja alternativa (opcional): Epic, GOG, etc.

Se você joga fora da Steam, o **Heroic Games Launcher** cobre Epic e GOG com Proton:

```bash
paru -S heroic-games-launcher-bin
```

Resumo: **multilib ligado → drivers 32‑bit → steam + gamescope + gamemode + mangohud → Proton ligado
para todos os títulos.** No bare metal, com GPU real, a experiência fica muito próxima (às vezes melhor)
do Windows.

---

## 9. Parte 6 — Personalização (temas, fontes, ícones)

Aqui é onde você deixa "a sua cara". Sugestão de base coerente e bonita:

```bash
# Tema GTK + ícones + cursor (Catppuccin combina com a config do Hyprland acima)
paru -S catppuccin-gtk-theme-mocha papirus-icon-theme catppuccin-cursors-mocha

# Ferramentas para aplicar temas GTK e Qt:
paru -S nwg-look qt6ct kvantum
```

- **nwg-look** — GUI pra aplicar tema/ícone/fonte GTK no Wayland.
- **qt6ct + kvantum** — controlam a aparência de apps Qt (por isso o `QT_QPA_PLATFORMTHEME=qt6ct` na
  config do Hyprland).

Para a **Waybar**, edite `~/.config/waybar/config.jsonc` e `~/.config/waybar/style.css`. A Waybar tem
templates prontos na comunidade que você adapta — comece copiando o exemplo padrão de
`/etc/xdg/waybar/` e vá enxugando.

Dica de fluxo de trabalho: ao invés de reinventar cada peça, **garimpe dotfiles** de projetos como
JaKooLit, ML4W ou end‑4, copie só os pedaços que gostar (a config da Waybar, o tema do wofi) e cole no
seu. Você mantém "máximo controle" mas não parte do zero absoluto no visual.

---

## 10. Parte 7 — Dotfiles: versionar tudo

Este é **o passo mais importante do plano** — é o que transforma "configurei uma VM" em "tenho um
ambiente reproduzível que migra pro bare metal em minutos".

### 9.1 O que versionar

Basicamente `~/.config/` (as configs) + alguns arquivos do home + a lista de pacotes:

```
~/.config/hypr/        # Hyprland, hyprlock, hypridle, hyprpaper
~/.config/waybar/
~/.config/wofi/
~/.config/swaync/
~/.config/kitty/
~/.config/starship.toml
~/.zshrc  ~/.zprofile
```

### 9.2 Estratégia com GNU Stow (limpa e reversível)

O **Stow** cria links simbólicos do repositório pro seu home. Estrutura sugerida:

```bash
paru -S stow
mkdir -p ~/dotfiles
cd ~/dotfiles

# Uma pasta por "pacote", espelhando o caminho a partir do home:
mkdir -p hypr/.config/hypr
mv ~/.config/hypr/* hypr/.config/hypr/

mkdir -p waybar/.config/waybar
mv ~/.config/waybar/* waybar/.config/waybar/

mkdir -p zsh
mv ~/.zshrc zsh/.zshrc

# Aplicar (cria os symlinks de volta no home):
cd ~/dotfiles
stow hypr waybar zsh
```

Depois é só versionar:

```bash
cd ~/dotfiles
git init -b main
git add -A
git commit -m "Dotfiles iniciais: Hyprland + waybar + zsh"
gh repo create dotfiles --private --source=. --push
```

### 9.3 Exportar a lista de pacotes (o "outro metade" da config)

```bash
# Pacotes instalados explicitamente dos repos oficiais:
pacman -Qqen > ~/dotfiles/pkglist-oficial.txt
# Pacotes do AUR:
pacman -Qqem > ~/dotfiles/pkglist-aur.txt

cd ~/dotfiles && git add -A && git commit -m "Lista de pacotes"
git push
```

Reinstalar tudo depois é um comando:

```bash
sudo pacman -S --needed - < pkglist-oficial.txt
paru -S --needed - < pkglist-aur.txt
```

> Pronto: **seu ambiente inteiro agora cabe num `git clone`.**

---

## 11. Parte 8 — Migração da VM para o bare metal

O grande final. Você **não** transfere o disco da VM (aquilo herda drivers e boot da máquina virtual e
dá dor de cabeça). Você faz uma **instalação limpa** no hardware real e **restaura os dotfiles**.

### Checklist de migração

1. **Na VM, garanta que está tudo commitado e no GitHub:** dotfiles + `pkglist-oficial.txt` +
   `pkglist-aur.txt`. Esse é o seu "backup da alma da máquina".
2. **Pen drive de boot:** grave a ISO do Arch num pendrive (no Windows use o Rufus ou Ventoy; no Linux,
   `dd` ou o `impi`/`etcher`).
3. **Backup do Windows / espaço em disco:** se for **dual boot**, redimensione a partição do Windows
   pelo próprio Gerenciador de Disco do Windows antes, deixando espaço não alocado pro Arch. Se for
   **substituir** o Windows, faça backup do que importa.
4. **Boot pela BIOS/UEFI real:** desative o **Secure Boot** (o Arch padrão não assina o boot) e, se
   houver, o **Fast Boot**. Deixe em modo UEFI.
5. **Repita a Parte 1 (instalação do Arch)** no disco real. Diferenças em relação à VM:
   - O device provavelmente é `/dev/nvme0n1` (partições `p1`, `p2`), não `/dev/sda`.
   - **Wi‑Fi** no ambiente live usa `iwctl`:
     ```
     iwctl
     station wlan0 scan
     station wlan0 get-networks
     station wlan0 connect NOME_DA_REDE
     exit
     ```
   - **Microcode correto:** `intel-ucode` ou `amd-ucode` conforme a CPU **real** (não a do host).
   - **Driver de vídeo real** (isto a VM não tinha): instale conforme a GPU:
     - Intel: `mesa vulkan-intel intel-media-driver`
     - AMD: `mesa vulkan-radeon libva-mesa-driver`
     - NVIDIA: `nvidia-dkms nvidia-utils` + ajustes de Wayland (ver wiki Hyprland/NVIDIA).
   - **Para jogos (Parte 5):** é aqui que faz sentido habilitar o `multilib`, instalar as bibliotecas
     `lib32-*` do seu driver e o Steam. Na VM não valia a pena; no hardware real, sim.
   - Se for **dual boot**, o `systemd-boot` detecta o Windows automaticamente na maioria dos casos
     (via `os-prober` não é necessário no systemd-boot; ele lê o EFI). Confirme que a partição EFI do
     Windows está montada em `/boot` ou use a mesma ESP.
6. **Crie o usuário, instale `paru`** (Parte 2).
7. **Restaure o ambiente:**
   ```bash
   git clone git@github.com:SEU_USER/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   sudo pacman -S --needed - < pkglist-oficial.txt
   paru -S --needed - < pkglist-aur.txt
   stow hypr waybar zsh kitty wofi swaync   # recria os symlinks
   ```
8. **Ajustes finos do bare metal na config do Hyprland:**
   - **Remova/comente** os ajustes de VM: o bloco `env = LIBGL_ALWAYS_SOFTWARE` (se tiver descomentado)
     e, se o cursor funcionar normal, pode testar `no_hardware_cursors = false`.
   - **Ligue as sombras** e aumente blur/animações — agora tem GPU de verdade.
   - Configure o **monitor real** com resolução e refresh corretos:
     `monitor = eDP-1, 1920x1080@144, 0x0, 1` (use `hyprctl monitors` pra ver os nomes).
9. **Reboot e aproveite** — agora liso, com a mesma cara que você montou na VM.

> Resumo da filosofia: a VM foi o rascunho; o Git foi a ponte; o bare metal é a versão final.
> Você nunca "moveu" o sistema — você o **reconstruiu a partir da receita**, que é mais confiável.

---

## 12. Apêndice — Troubleshooting comum

| Sintoma | Causa provável | Solução |
|---|---|---|
| **Tela preta ao subir o Hyprland na VM** | Cursor de hardware | `cursor { no_hardware_cursors = true }` na config. |
| **Ainda tela preta / "failed to open DRM"** | Sem aceleração 3D na VM | Descomente `env = LIBGL_ALWAYS_SOFTWARE,1` e `WLR_RENDERER_ALLOW_SOFTWARE,1`. Confirme "Accelerate 3D" ligado na VMware. |
| **Cursor invisível** | Tamanho/tema de cursor | Defina `env = XCURSOR_SIZE,24` e aplique um tema de cursor com `nwg-look`. |
| **Sem áudio** | WirePlumber não subiu | `systemctl --user status wireplumber`; reinstale `pipewire wireplumber`. |
| **Apps gráficos não pedem senha (polkit)** | Agente polkit ausente | Garanta `exec-once = systemctl --user start hyprpolkitagent`. |
| **Compartilhar tela não funciona (Teams/Meet)** | Portal ausente | Instale `xdg-desktop-portal-hyprland` e relogue. |
| **VS Code / Chrome borrados no Wayland** | Escala/HiDPI | Force `--ozone-platform=wayland` ou rode em XWayland; ajuste `env = GDK_SCALE`. |
| **`docker` pede sudo sempre** | Grupo não aplicado | `sudo usermod -aG docker $USER` e **relogar**. |
| **Nerd Font não mostra ícones na Waybar** | Fonte errada no CSS | Aponte `font-family` do `style.css` pra uma Nerd Font instalada. |
| **Não bota no bare metal após instalar** | Entrada do systemd-boot / Secure Boot | Revise `/boot/loader/entries/arch.conf` (UUID certo) e desative Secure Boot. |
| **`steam` não é encontrado no pacman** | Repositório multilib desligado | Descomente `[multilib]` em `/etc/pacman.conf` e rode `sudo pacman -Syu`. |
| **Jogo não abre / erro de Vulkan 32-bit** | Faltam bibliotecas `lib32-*` | Instale o `lib32-vulkan-*` correspondente à sua GPU. |
| **Jogo com tela cheia bugando no Hyprland** | Tiling brigando com o jogo | Rode dentro do `gamescope` (`gamescope -f -- %command%`) e use as `windowrulev2`. |

### Comandos de diagnóstico úteis

```bash
hyprctl monitors          # monitores detectados
hyprctl clients           # janelas abertas
journalctl -b -p err      # erros do boot atual
systemctl --user status   # serviços do usuário (pipewire, portal, etc.)
```

### Referências oficiais (mantêm-se atualizadas)

- Arch Installation guide — <https://wiki.archlinux.org/title/Installation_guide>
- Hyprland Wiki (config, VM/Virtual-GPU, NVIDIA) — <https://wiki.hypr.land/>
- Hyprland na ArchWiki — <https://wiki.archlinux.org/title/Hyprland>
- Gerenciamento de dotfiles (Stow) — <https://wiki.archlinux.org/title/Dotfiles>

---

*Bom proveito. Comece pela VM sem medo de errar — é justamente o lugar pra quebrar e refazer.*
