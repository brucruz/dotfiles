## Dotfiles

Personal dotfiles for macOS. Tracks shell, git, editor, and terminal config.

### New Machine Setup

```sh
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 2. Clone this repo
git clone git@github.com:brucruz/dotfiles.git ~/code/brucruz/dotfiles
cd ~/code/brucruz/dotfiles

# 3. Install brew packages and link dotfiles
./scripts/install.sh --brew

# 4. Neovim config (separate repo)
git clone git@github.com:brucruz/kickstart.nvim.git ~/.config/nvim

# 5. Install extras not in Homebrew
curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | sh
cargo install zellij

# 6. Restart your terminal
```

### What's Included

| Path | What |
|------|------|
| `dotfiles/zshrc` | Shell config (oh-my-zsh, zinit, nvm, pyenv, rbenv) |
| `dotfiles/zprofile` | Login shell bootstrap (Homebrew, pyenv) |
| `dotfiles/aliases` | Shell aliases |
| `dotfiles/gitconfig` | Git config (identity via `~/.gitconfig.personal`) |
| `dotfiles/gitignore_global` | Global gitignore |
| `dotfiles/.config/ghostty/` | Ghostty terminal config |
| `dotfiles/.config/alacritty/` | Alacritty terminal config |
| `dotfiles/.config/yazi/` | Yazi file manager config |
| `dotfiles/.config/zellij/` | Zellij multiplexer config |
| `dotfiles/.config/amp/` | Amp AI editor config |
| `Brewfile` | Homebrew packages, casks, and extensions |

### Usage

```sh
# Dry run (preview changes)
./scripts/install.sh --dry-run

# Apply dotfiles only
./scripts/install.sh

# Apply dotfiles + install brew packages
./scripts/install.sh --brew
```

### Private Config

Git identity is stored in `~/.gitconfig.personal` (local-only, never committed).
The installer creates it from `private.example/gitconfig.personal.example` and prompts for your name/email.

Other private contracts in `private.example/`:
- `npmrc.example` — for npm registry auth tokens
- `netrc.example` — for machine/login credentials
