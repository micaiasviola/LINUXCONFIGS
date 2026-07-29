#!/usr/bin/env bash
set -euo pipefail
echo ">> Gaming setup — rode isto NO BARE METAL, nao na VM."

if systemd-detect-virt --quiet; then
    echo "!! Detectei ambiente virtualizado ($(systemd-detect-virt)). Aborte se nao for de proposito."
    read -rp "Continuar mesmo assim? [s/N] " ans
    [[ "${ans,,}" == "s" ]] || exit 1
fi

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
