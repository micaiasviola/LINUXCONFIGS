# Migração VM → Bare Metal (dual boot com Windows no MESMO PC)

Guia para instalar o Arch + Hyprland **ao lado do Windows** na sua máquina real,
reaproveitando este repositório. É **destrutivo por natureza** (mexe em partições):
leia tudo antes e faça backup.

> Pré-requisito mental: o ensaio na VM já validou o software. Aqui o que é novo e
> arriscado é o **particionamento ao lado do Windows** e os **drivers reais**.

---

## 0. Backup (inegociável)
- Copie seus arquivos importantes do Windows para um HD externo/nuvem.
- Anote a chave do **BitLocker** (se usar): Painel → "Criptografia de unidade de disco BitLocker".

## 1. Preparar o Windows (antes de criar o pendrive)
1. **Desligar o Fast Startup:** Painel de Controle → Opções de Energia → "Escolher a função
   dos botões" → "Alterar configurações indisponíveis" → **desmarque** "Ligar inicialização
   rápida". (Senão o Windows trava a partição e o Arch não monta.)
2. **Suspender/desligar o BitLocker** (se estiver ligado) — senão pode pedir a chave ou travar.
3. **Encolher a partição do Windows** para abrir espaço: Iniciar → "Gerenciamento de disco" →
   botão direito no C: → "Diminuir volume" → libere, por ex., 60–120 GB. **Deixe o espaço
   como NÃO ALOCADO** (não crie partição; o instalador do Arch usa esse espaço livre).

## 2. Criar o pendrive de boot (Rufus)
1. Baixe o **Rufus** em https://rufus.ie (versão portátil, não precisa instalar).
2. Espete um pendrive de **8 GB+** (será **APAGADO** — salve o que tiver nele).
3. No Rufus:
   - **Dispositivo:** selecione o pendrive (confira 2x que é ele!).
   - **Seleção de boot:** SELECIONAR → escolha `archlinux-x86_64.iso`.
   - **Esquema de partição:** `GPT` · **Sistema de destino:** `UEFI (não CSM)`.
   - **INICIAR** → se perguntar, escolha **"Gravar em modo Imagem DD"**.
   - Confirme o aviso de que vai apagar o pendrive.
4. Ao terminar, ejete com segurança.

## 3. Bootar pelo pendrive
1. Reinicie e entre no **menu de boot** (tecla varia: F12/F10/Esc/F2/Del — veja a marca da placa).
2. Na BIOS/UEFI, se precisar: **desligue o Secure Boot** e confirme modo **UEFI**.
3. Escolha a entrada **UEFI** do pendrive → abre o instalador do Arch.

## 4. Instalar o Arch AO LADO do Windows
Use o `archinstall` (mais simples). Escolhas importantes:
- Teclado/locale: `br-abnt2`, `pt_BR.UTF-8` · Mirrors: `Brazil`
- **Disco:** modo **Manual** — NÃO apague o disco todo! Crie as partições do Arch **no espaço
  não alocado** que você liberou:
  - use a partição **EFI já existente** do Windows para o boot (monte em `/boot`, NÃO formate),
  - crie uma partição raiz `ext4` montada em `/` no espaço livre.
- **Bootloader: `GRUB`** (detecta o Windows via os-prober).
- **Network: `NetworkManager`** · **Profile: `Minimal`** (o Hyprland vem do install.sh)
- Crie seu usuário com **superuser (sudo)** · marque o repositório **`multilib`**.
- Instale e reinicie (remova o pendrive).

> Depois do 1º boot, para o GRUB enxergar o Windows:
> `sudo pacman -S --needed os-prober`, descomente `GRUB_DISABLE_OS_PROBER=false` em
> `/etc/default/grub`, e rode `sudo grub-mkconfig -o /boot/grub/grub.cfg`.

## 5. Pós-instalação — trazer este repo e rodar
```bash
sudo pacman -Sy --needed git
git clone https://github.com/micaiasviola/LINUXCONFIGS.git ~/linuxconfigs
cd ~/linuxconfigs/dotfiles
bash scripts/install.sh
```
(o `open-vm-tools` só instala em VM; no bare metal ele é pulado automaticamente.)

## 6. Ajustes específicos de bare metal
- **Monitores (3 telas):** rode `nwg-displays` (GUI) para arranjar, OU edite
  `~/.config/hypr/monitors.conf` (comente o perfil VM, use os nomes reais de `hyprctl monitors all`).
- **Remover os ajustes de VM** em `~/.config/hypr/hyprland.conf`:
  - `cursor { no_hardware_cursors }` pode voltar a `false`;
  - garanta que `env = LIBGL_ALWAYS_SOFTWARE,1` está **comentado**;
  - `decoration { shadow { enabled = true } }` (liga sombra).
- **Terminal:** no bare metal o `kitty` funciona (GPU real). Se quiser, troque
  `$terminal = foot` de volta para `$terminal = kitty`.
- **Driver de vídeo real:**
  - Intel: `mesa vulkan-intel` · AMD: `mesa vulkan-radeon` · NVIDIA: `nvidia-dkms nvidia-utils`
    + ajustes de Wayland (ver wiki Hyprland/NVIDIA).
- **Jogos:** `bash scripts/bare-metal-gaming.sh` (Steam + drivers 32-bit + gamescope/gamemode).

## 7. Se algo der errado no boot
- **Só entra no Windows (sem menu):** rode o passo do `os-prober` (seção 4) ou, no Windows,
  verifique a ordem de boot na UEFI (coloque o GRUB/Arch antes do Windows Boot Manager).
- **Não entra em nada:** boote pelo pendrive → modo de recuperação → `arch-chroot` → reinstale o GRUB.
