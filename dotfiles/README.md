# dotfiles — Hyprland + ambiente de dev (Catppuccin Mocha)

Ambiente completo para **Arch Linux + Hyprland**, versionado com **GNU Stow**.
Estes arquivos foram **preparados no Windows como staging** — a instalação de fato
roda **dentro do Arch** (`pacman`/`paru`/`stow` não existem no Windows).

> Origem: `prompt-claude-code-setup.md`. Este repo é o "gêmeo executável" já materializado.

## Como usar (no Arch, não no Windows)

1. Faça a instalação **base** do Arch (particionamento, `pacstrap`, `systemd-boot`,
   usuário com sudo) e reinicie para dentro do sistema, com internet.
2. Bootstrap mínimo:
   ```bash
   sudo pacman -Syu --needed git base-devel stow
   ```
3. Traga esta pasta para `~/dotfiles` (git clone, `scp`, pendrive, pasta compartilhada da VM…).
4. **Edite `scripts/install.sh`** — o bloco `>>> PREENCHA <<<` no topo (nome/e-mail do git,
   layout de teclado). Defaults atuais: nome `Leo`, e-mail `tecnologia@ecqua.com.br`, layout `br`.
5. Rode:
   ```bash
   cd ~/dotfiles
   chmod +x scripts/*.sh
   ./scripts/install.sh
   ```
   Ele faz as Etapas 0–11: `pacman -Syu`, multilib, `paru`, pacotes por categoria (pede
   confirmação), `stow` (com backup do que existir), fnm/pyenv/uv, docker, git, chave SSH,
   pkglists e commit inicial.

6. Relogue e suba o Hyprland: digite `Hyprland` num TTY (ou use o SDDM, se instalou).

## Estrutura (pacotes Stow)

```
dotfiles/
├── hypr/.config/hypr/      hyprland.conf, monitors.conf, hyprpaper, hypridle, hyprlock
├── waybar/.config/waybar/  config.jsonc, style.css
├── wofi/.config/wofi/      config, style.css
├── swaync/.config/swaync/  config.json, style.css
├── kitty/.config/kitty/    kitty.conf
├── starship/.config/       starship.toml
├── zsh/.zshrc
├── scripts/                install.sh, bare-metal-gaming.sh
├── pkglist-oficial.txt     (gerado no Arch)
└── pkglist-aur.txt         (gerado no Arch)
```

`stow hypr` cria `~/.config/hypr -> ~/dotfiles/hypr/.config/hypr`, e assim por diante.

## Diferenças que ajustei vs. o prompt (alinhamento com a wiki atual)

- **`windowrulev2` → `windowrule`**: a sintaxe foi unificada; `windowrulev2` está deprecado.
  Todas as regras de janela usam `windowrule = ...` agora.
- **Backend `aquamarine`** (substituiu o wlroots na 0.42+): as variáveis `WLR_*` antigas
  não valem mais. Removi o fallback `WLR_RENDERER_ALLOW_SOFTWARE` do perfil de VM e deixei
  só `LIBGL_ALWAYS_SOFTWARE` (que é do Mesa e continua válido), comentado.
- **`shadow` é subseção** de `decoration { shadow { enabled = ... } }` — mantido correto.
- **Cursor de hardware** em VM controlado por `cursor { no_hardware_cursors = true }`.

> ⚠️ Não consegui validar 100% da sintaxe da wiki oficial a partir do Windows (a wiki é
> renderizada no cliente e a ArchWiki está atrás de anti-bot; um summarizer chegou a alucinar
> datas). Um boato de "Lua substituiu o hyprlang na 0.55" **não foi confirmado** — só apareceu
> em sites de conteúdo gerado por IA com datas contraditórias, então **ignorei**: o formato
> `.conf` segue válido. **Confirme na máquina real** com `hyprland --version` e, se algo destoar,
> ajuste o `hyprland.conf` (as opções sensíveis a versão estão comentadas no arquivo).

## Checklist VM → BARE METAL (3 monitores + jogos)

- [ ] `monitors.conf`: comentar o perfil VM, descomentar/gerar o perfil dos 3 monitores.
      Rode `hyprctl monitors all`, anote nomes/resoluções/ordem física e preencha.
- [ ] `hyprland.conf`: `cursor.no_hardware_cursors` pode voltar a `false`; remover o `env`
      de software render; `decoration { shadow { enabled = true } }`.
- [ ] Instalar o **driver de vídeo real** (mesa + vulkan da GPU; NVIDIA exige ajustes extras
      de Wayland — ver wiki Hyprland/NVIDIA).
- [ ] `./scripts/bare-metal-gaming.sh` (Steam + drivers 32-bit + gamescope/gamemode/mangohud).
- [ ] Reaplicar dotfiles (`stow`) e reinstalar pacotes via `pkglist-*.txt` se for máquina nova:
      ```bash
      sudo pacman -S --needed - < pkglist-oficial.txt
      paru  -S --needed - < pkglist-aur.txt
      ```

## Notas

- **Quebras de linha:** o `.gitattributes` força `LF` para os `.sh`/configs (foram criados no
  Windows). Se ainda assim um script reclamar de `\r`, rode `sed -i 's/\r$//' scripts/*.sh`.
- **Wallpaper:** o `install.sh` tenta baixar um Catppuccin para `~/.config/hypr/wall.jpg`.
  Se falhar, coloque um manualmente (o `hyprpaper` precisa do arquivo existir).
- **Teclado:** default `br` (ABNT2). Para US, ajuste `KB_LAYOUT="us"` no `install.sh`
  (ele remove o `kb_variant`).
