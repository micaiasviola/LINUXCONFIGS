# Este repositório

Guias e um retrato das configurações do desktop **Arch Linux + Hyprland**:
`guia-arch-hyprland-dev.md`, `prompt-claude-code-setup.md` e a pasta
`dotfiles/` com `hypr`, `kitty`, `foot`, `swaync`, `starship`, `scripts` e as
listas de pacotes.

## ⚠️ Antes de qualquer coisa: este NÃO é o repositório vivo

Existe outro repositório cobrindo a mesma matéria — **`~/dotfiles`** — e é
**ele** que está no ar. Os symlinks de `~/.config` apontam para lá:

```bash
readlink -f ~/.config/hypr     # -> /home/kabala/dotfiles/hypr
```

**Consequência que engana:** editar `dotfiles/hypr/...` **aqui** não muda
nada no sistema. O arquivo tem o mesmo nome, a mesma cara, e é inerte. Já em
`~/dotfiles`, salvar publica na hora, porque lá é o mesmo arquivo que
`~/.config` (mesmo inode).

Confira em qual dos dois você está antes de editar:

```bash
git rev-parse --show-toplevel      # LINUXCONFIGS ou dotfiles?
```

**Se a tarefa é mudar o comportamento do desktop, o alvo é `~/dotfiles`.**
Aqui só se mexe quando a tarefa é sobre a *documentação* ou sobre o retrato
de instalação.

## O que este repositório é bom para

- **`guia-arch-hyprland-dev.md`** — o passo a passo de montar a máquina do
  zero.
- **`dotfiles/pkglist-oficial.txt` e `pkglist-aur.txt`** — o que instalar.
- **`dotfiles/MIGRACAO-BARE-METAL.md`** — dual boot no mesmo PC.

Se uma configuração daqui divergir de `~/dotfiles`, **`~/dotfiles` é a
verdade** — ele é o que roda. Este repositório está parado desde 29/07/2026;
aquele recebe commits toda semana.

## Ver também

- `~/.claude/CLAUDE.md` — o ciclo de sprint (abrir a worktree no começo,
  reaproveitar entre sessões, fechar com commit + push + PR + remoção) e as
  armadilhas do Hyprland em Lua. Vale aqui como em qualquer projeto.
- `~/dotfiles/CLAUDE.md` — as regras do repositório que está no ar.
