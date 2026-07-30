#!/usr/bin/env bash
# =============================================================================
#  install.sh — Monta o ambiente Hyprland/dev a partir de um Arch base limpo.
#  RODE ISTO DENTRO DO ARCH (nao no Windows/VM host), logado como usuario comum
#  com sudo e internet.  Espelha as Etapas 0-11 do prompt-claude-code-setup.md.
#
#  Uso:   cd ~/dotfiles && ./scripts/install.sh
#  Nada e destrutivo em silencio: configs existentes viram <arquivo>.bak-<ts>.
# =============================================================================
set -euo pipefail

# ----------------------------------------------------------------------------
# >>> PREENCHA ESTES 3 CAMPOS <<<
# ----------------------------------------------------------------------------
GIT_NAME="Leo"                              # <<< troque pelo seu nome
GIT_EMAIL="tecnologia@ecqua.com.br"         # <<< confira seu e-mail
KB_LAYOUT="br"                              # "br" (ABNT2) ou "us"
# ----------------------------------------------------------------------------

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_PKGS=(hypr waybar wofi swaync kitty foot zsh starship)
TS="$(date +%Y%m%d-%H%M%S)"

c_info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
c_ok()   { printf '\033[1;32mok\033[0m %s\n' "$*"; }
c_warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
ask()    { read -rp "$(printf '\033[1;35m?\033[0m %s [s/N] ' "$1")" a; [[ "${a,,}" == "s" ]]; }

# ---------------------------------------------------------------- Etapa 0 ----
c_info "Etapa 0 — Sanity checks"
[[ $EUID -ne 0 ]] || { c_warn "Nao rode como root. Use seu usuario comum."; exit 1; }
whoami
sudo -v || { c_warn "sudo indisponivel."; exit 1; }
ping -c2 archlinux.org >/dev/null && c_ok "internet ok" || c_warn "sem internet?"
VIRT="$(systemd-detect-virt || true)"; c_info "Virtualizacao: ${VIRT:-nenhuma}"
c_info "GPU:"; lspci -k | grep -A2 -i vga || true

# ---------------------------------------------------------------- Etapa 1 ----
c_info "Etapa 1 — Versao do Hyprland (para casar sintaxe com a wiki)"
if command -v hyprland >/dev/null; then hyprland --version || true
else c_warn "hyprland ainda nao instalado (sera instalado adiante)."; fi

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel stow

# ---------------------------------------------------------------- Etapa 2 ----
c_info "Etapa 2 — Habilitar multilib (necessario depois p/ Steam)"
if grep -qE '^\s*#\s*\[multilib\]' /etc/pacman.conf; then
    sudo cp /etc/pacman.conf "/etc/pacman.conf.bak-$TS"
    sudo sed -i '/^\s*#\s*\[multilib\]/,/^\s*#\s*Include/ s/^\s*#\s*//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
    c_ok "multilib habilitado"
else
    c_ok "multilib ja habilitado"
fi

# ---------------------------------------------------------------- Etapa 3 ----
c_info "Etapa 3 — paru (AUR helper)"
if ! command -v paru >/dev/null; then
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmp/paru"
    ( cd "$tmp/paru" && makepkg -si --noconfirm )
    rm -rf "$tmp"
    c_ok "paru instalado"
else
    c_ok "paru ja presente"
fi

# ---------------------------------------------------------------- Etapa 4 ----
c_info "Etapa 4 — Pacotes (paru resolve repo + AUR)"
PKG_AUDIO=(pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber polkit)
PKG_HYPR=(hyprland hyprpaper hyprlock hypridle hyprpicker hyprpolkitagent
          xdg-desktop-portal-hyprland qt5-wayland qt6-wayland)
PKG_SESSION=(networkmanager waybar wofi swaync kitty foot wl-clipboard cliphist
             grim slurp thunar thunar-volman gvfs brightnessctl playerctl
             pavucontrol network-manager-applet)
PKG_FONTS=(ttf-jetbrains-mono-nerd ttf-firacode-nerd noto-fonts noto-fonts-emoji
           ttf-font-awesome)
PKG_CLI=(zsh starship ripgrep fd bat eza fzf zoxide tmux lazygit git-delta
         fastfetch btop unzip wget curl jq nano)
PKG_DEV=(git github-cli fnm pyenv uv docker docker-compose docker-buildx
         visual-studio-code-bin google-chrome)
PKG_THEME=(catppuccin-gtk-theme-mocha papirus-icon-theme catppuccin-cursors-mocha
           nwg-look qt6ct kvantum)

ALL=("${PKG_AUDIO[@]}" "${PKG_HYPR[@]}" "${PKG_SESSION[@]}" "${PKG_FONTS[@]}"
     "${PKG_CLI[@]}" "${PKG_DEV[@]}" "${PKG_THEME[@]}")

printf '   %s\n' "${ALL[@]}" | column -c 90 2>/dev/null || printf '   %s\n' "${ALL[@]}"
if ask "Instalar TODOS os pacotes acima?"; then
    paru -S --needed "${ALL[@]}"
    c_ok "pacotes instalados"
else
    c_warn "Pulei a instalacao de pacotes (voce pode rodar depois)."
fi

if ask "Instalar o SDDM (gerenciador de login grafico)?"; then
    paru -S --needed sddm
    sudo systemctl enable sddm.service
    c_ok "sddm habilitado (inicia no proximo boot)"
fi

# Garantir o NetworkManager ativo (o nm-applet depende dele; base minima nao traz).
if pacman -Qq networkmanager >/dev/null 2>&1; then
    sudo systemctl enable --now NetworkManager
    c_ok "NetworkManager ativo"
fi

# Em VM VMware: open-vm-tools ajusta a resolucao a janela + clipboard/drag-drop.
# Sem ele o desktop costuma ficar maior que a area visivel (janelas fora da tela).
if [[ "$VIRT" == "vmware" ]]; then
    paru -S --needed open-vm-tools
    sudo systemctl enable --now vmtoolsd vmware-vmblock-fuse
    c_ok "open-vm-tools ativo (resize automatico da tela)"
fi

# ---------------------------------------------------------------- Etapa 5/6 --
c_info "Etapa 5/6 — Aplicar dotfiles via GNU Stow (backup do que existir)"
declare -A TARGETS=(
    [hypr]="$HOME/.config/hypr"
    [waybar]="$HOME/.config/waybar"
    [wofi]="$HOME/.config/wofi"
    [swaync]="$HOME/.config/swaync"
    [kitty]="$HOME/.config/kitty"
    [starship]="$HOME/.config/starship.toml"
    [zsh]="$HOME/.zshrc"
)
for pkg in "${STOW_PKGS[@]}"; do
    t="${TARGETS[$pkg]}"
    if [[ -e "$t" && ! -L "$t" ]]; then
        mv "$t" "${t}.bak-$TS"
        c_warn "backup: ${t} -> ${t}.bak-$TS"
    fi
done
( cd "$DOTFILES" && stow -t "$HOME" "${STOW_PKGS[@]}" )
c_ok "symlinks criados"

# Aplicar o layout de teclado escolhido no hyprland.conf (se diferente do padrao)
if [[ "$KB_LAYOUT" == "us" ]]; then
    sed -i 's/^\(\s*kb_layout\s*=\).*/\1 us/' "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || true
    sed -i '/^\s*kb_variant\s*=/d' "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || true
fi

# Papel de parede (Catppuccin) — tenta baixar; se falhar, avisa.
WALL="$HOME/.config/hypr/wall.jpg"
if [[ ! -f "$WALL" ]]; then
    curl -fsSL -o "$WALL" \
      "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/main/landscapes/evening-sky.png" \
      && c_ok "wallpaper baixado" \
      || c_warn "nao consegui baixar wallpaper; coloque um em $WALL manualmente."
fi

# ---------------------------------------------------------------- Etapa 7 ----
c_info "Etapa 7 — Ambiente de dev"

# Node via fnm
if command -v fnm >/dev/null; then
    eval "$(fnm env)"
    fnm install --lts && fnm default lts-latest || c_warn "fnm: instale a LTS manualmente."
    command -v corepack >/dev/null && corepack enable || true
fi

# Python via pyenv + uv
if command -v pyenv >/dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    pyenv install -s 3.12 && pyenv global 3.12 || c_warn "pyenv: instale o 3.12 manualmente."
fi

# Docker
if command -v docker >/dev/null; then
    sudo systemctl enable --now docker.service
    sudo usermod -aG docker "$USER"
    c_warn "Voce foi adicionado ao grupo 'docker'. RELOGUE para usar docker sem sudo."
fi

# Git
git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
if command -v delta >/dev/null; then
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
fi
c_ok "git configurado ($GIT_NAME <$GIT_EMAIL>)"

# Chave SSH
if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
    c_ok "chave SSH ed25519 gerada"
    c_info "Sua chave publica (suba no GitHub, ou rode 'gh auth login'):"
    cat "$HOME/.ssh/id_ed25519.pub"
fi

# Shell padrao -> zsh
if [[ "$SHELL" != *zsh ]]; then
    if ask "Definir zsh como shell padrao (chsh)?"; then
        chsh -s /usr/bin/zsh
        c_ok "shell padrao = zsh (efetivo no proximo login)"
    fi
fi

# ---------------------------------------------------------------- Etapa 10 ---
c_info "Etapa 10 — Versionar dotfiles e gerar pkglists"
if git -C "$DOTFILES" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    c_ok "dotfiles ja versionado (repo git detectado); pulando git init"
else
    ( cd "$DOTFILES" && git init -b main && git add -A \
      && git commit -m "Configuracao inicial do ambiente Hyprland/dev" )
    c_ok "repo git inicializado em $DOTFILES"
fi
pacman -Qqen > "$DOTFILES/pkglist-oficial.txt"
pacman -Qqem > "$DOTFILES/pkglist-aur.txt"
c_ok "pkglist-oficial.txt e pkglist-aur.txt gerados"

# ---------------------------------------------------------------- Etapa 11 ---
c_info "Etapa 11 — Verificacao"
command -v hyprland >/dev/null && hyprland --version | head -n1 || true
for pkg in "${STOW_PKGS[@]}"; do
    t="${TARGETS[$pkg]}"; [[ -L "$t" ]] && c_ok "symlink $t" || c_warn "faltou symlink $t"
done

cat <<'EOF'

============================================================
 PRONTO. Proximos passos:
   1) Relogue (grupo docker + shell zsh).
   2) Suba o Hyprland:  digite 'Hyprland' num TTY  (ou use o SDDM se instalou).
   3) gh auth login     (para o GitHub via CLI/SSH).
   4) No BARE METAL: edite ~/.config/hypr/monitors.conf (3 telas),
      ajuste ~/.config/hypr/hyprland.conf (cursor/shadow/env), e rode
      ./scripts/bare-metal-gaming.sh
============================================================
EOF
