#!/bin/zsh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOTFILES_DIR="$REPO_ROOT/dotfiles"
PRIVATE_EXAMPLE_DIR="$REPO_ROOT/private.example"
DRY_RUN=0
INSTALL_BREW=0
FULL=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --brew) INSTALL_BREW=1 ;;
    --full) FULL=1; INSTALL_BREW=1 ;;
  esac
done

link_file() {
  source_name="$1"
  target_path="$2"
  source_path="$DOTFILES_DIR/$source_name"
  if [[ ! -e "$source_path" ]]; then
    echo "skip: missing source $source_path"
    return 0
  fi
  if [[ -L "$target_path" ]]; then
    if [[ "$(readlink "$target_path")" == "$source_path" ]]; then
      echo "ok: $target_path already linked"
      return 0
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: would replace symlink $target_path -> $source_path"
      return 0
    fi
    rm "$target_path"
    ln -s "$source_path" "$target_path"
    echo "updated: $target_path"
    return 0
  fi
  if [[ -e "$target_path" ]]; then
    backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: would move $target_path to $backup_path"
      echo "dry-run: would create symlink $target_path -> $source_path"
      return 0
    fi
    mv "$target_path" "$backup_path"
    echo "backup: $target_path -> $backup_path"
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry-run: would create symlink $target_path -> $source_path"
    return 0
  fi
  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  echo "linked: $target_path -> $source_path"
}

ensure_private_file() {
  source_path="$1"
  target_path="$2"
  if [[ -e "$target_path" ]]; then
    echo "ok: $target_path already exists"
    return 0
  fi
  if [[ ! -e "$source_path" ]]; then
    echo "skip: missing template $source_path"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry-run: would create $target_path from $source_path"
    return 0
  fi
  cp "$source_path" "$target_path"
  chmod 600 "$target_path"
  echo "created: $target_path from template"
}

prompt_for_git_identity() {
  target_path="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry-run: would prompt for git user.name/user.email in $target_path"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    echo "skip: non-interactive shell, cannot prompt for git identity"
    return 0
  fi
  current_name="$(git config --file "$target_path" --get user.name 2>/dev/null || true)"
  current_email="$(git config --file "$target_path" --get user.email 2>/dev/null || true)"
  has_placeholder=0
  if [[ "$current_name" == "Your Name" || "$current_email" == "your-email@example.com" ]]; then
    has_placeholder=1
  fi
  if [[ -n "$current_name" && -n "$current_email" && "$has_placeholder" -eq 0 ]]; then
    echo "ok: git identity already configured in $target_path"
    return 0
  fi
  echo "Configure git identity for this machine:"
  full_name=""
  while [[ -z "$full_name" ]]; do
    read -r "full_name?Git user.name: "
  done
  email=""
  while [[ -z "$email" || "$email" != *"@"*.* ]]; do
    read -r "email?Git user.email: "
  done
  signing_key=""
  read -r "signing_key?Git signing key (optional, press Enter to skip): "
  git config --file "$target_path" user.name "$full_name"
  git config --file "$target_path" user.email "$email"
  git config --file "$target_path" --unset-all user.signingkey >/dev/null 2>&1 || true
  if [[ -n "$signing_key" ]]; then
    git config --file "$target_path" user.signingkey "$signing_key"
  fi
  chmod 600 "$target_path"
  echo "updated: git identity in $target_path"
}

warn_if_insecure_permissions() {
  target_path="$1"
  if [[ ! -e "$target_path" ]]; then
    return 0
  fi
  mode="$(stat -f %Lp "$target_path" 2>/dev/null || true)"
  if [[ -z "$mode" ]]; then
    echo "warning: could not read permissions for $target_path"
    return 0
  fi
  if [[ "$mode" != "600" ]]; then
    echo "warning: $target_path permissions are $mode (recommended: 600)"
    echo "hint: run 'chmod 600 $target_path'"
  fi
}

link_app_support_file() {
  source_name="$1"
  app_support_subpath="$2"
  source_path="$REPO_ROOT/dotfiles/$source_name"
  target_path="$HOME/Library/Application Support/$app_support_subpath"
  if [[ ! -e "$source_path" ]]; then
    echo "skip: missing source $source_path"
    return 0
  fi
  if [[ -L "$target_path" ]]; then
    if [[ "$(readlink "$target_path")" == "$source_path" ]]; then
      echo "ok: $target_path already linked"
      return 0
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: would replace symlink $target_path -> $source_path"
      return 0
    fi
    rm "$target_path"
    ln -s "$source_path" "$target_path"
    echo "updated: $target_path"
    return 0
  fi
  if [[ -e "$target_path" ]]; then
    backup_path="${target_path}.backup.$(date +%Y%m%d%H%M%S)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: would move $target_path to $backup_path"
      echo "dry-run: would create symlink $target_path -> $source_path"
      return 0
    fi
    mv "$target_path" "$backup_path"
    echo "backup: $target_path -> $backup_path"
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry-run: would create symlink $target_path -> $source_path"
    return 0
  fi
  mkdir -p "$(dirname "$target_path")"
  ln -s "$source_path" "$target_path"
  echo "linked: $target_path -> $source_path"
}

print_optional_private_contract_guidance() {
  echo ""
  echo "Optional private contracts (local-only):"
  echo "- ~/.npmrc: use private.example/npmrc.example only if you need npm auth tokens."
  echo "- ~/.netrc: use private.example/netrc.example only if tools require machine/login credentials."
  echo "Do not commit real private files or tokens."
}

install_program() {
  name="$1"
  check_cmd="$2"
  install_cmd="$3"
  if eval "$check_cmd" >/dev/null 2>&1; then
    echo "ok: $name already installed"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry-run: would install $name"
    return 0
  fi
  echo "Installing $name..."
  eval "$install_cmd" || { echo "warning: $name install exited with status $?"; }
}


echo "Applying dotfiles from $DOTFILES_DIR"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Mode: dry-run"
fi

# Homebrew (install if missing when --brew or --full)
if [[ "$INSTALL_BREW" -eq 1 ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "dry-run: would install Homebrew"
    else
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
    fi
  else
    echo "ok: Homebrew already installed"
  fi
  if [[ "$DRY_RUN" -eq 0 ]] && command -v brew >/dev/null 2>&1; then
    echo "Installing brew packages..."
    brew bundle --file "$REPO_ROOT/Brewfile"
  elif [[ "$DRY_RUN" -eq 1 ]]; then
    echo "dry-run: would run brew bundle"
  fi
fi

# Programs (--full only)
if [[ "$FULL" -eq 1 ]]; then
  install_program "Oh My Zsh" \
    "[[ -d \$HOME/.oh-my-zsh ]]" \
    'KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'

  install_program "nvm" \
    "[[ -s \$HOME/.nvm/nvm.sh ]]" \
    'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'

  install_program "Atuin" \
    "command -v atuin" \
    'curl --proto "=https" --tlsv1.2 -sSf https://setup.atuin.sh | sh'

  install_program "Amp CLI" \
    "command -v amp" \
    'curl -fsSL https://ampcode.com/install.sh | bash'

fi

# Home-level dotfiles
link_file "zshrc" "$HOME/.zshrc"
link_file "zprofile" "$HOME/.zprofile"
link_file "aliases" "$HOME/.aliases"
link_file "gitconfig" "$HOME/.gitconfig"
link_file "gitignore_global" "$HOME/.gitignore_global"

# .config files
link_file ".config/ghostty/config" "$HOME/.config/ghostty/config"
link_file ".config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
link_file ".config/alacritty/alt-key.toml" "$HOME/.config/alacritty/alt-key.toml"
link_file ".config/alacritty/font-size.toml" "$HOME/.config/alacritty/font-size.toml"
link_file ".config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"
link_file ".config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
link_file ".config/amp/settings.json" "$HOME/.config/amp/settings.json"
link_file ".config/nvim" "$HOME/.config/nvim"

# Application Support files (macOS-specific paths)
link_app_support_file "cursor/settings.json" "Cursor/User/settings.json"
link_app_support_file "cursor/keybindings.json" "Cursor/User/keybindings.json"

# Git identity (private, local-only)
ensure_private_file "$PRIVATE_EXAMPLE_DIR/gitconfig.personal.example" "$HOME/.gitconfig.personal"
prompt_for_git_identity "$HOME/.gitconfig.personal"
warn_if_insecure_permissions "$HOME/.gitconfig.personal"
print_optional_private_contract_guidance

if [[ "$FULL" -eq 0 ]]; then
  echo ""
  echo "Tip: run with --full to also install Homebrew, brew packages, Oh My Zsh,"
  echo "     nvm, Atuin, and Amp CLI."
fi

echo ""
echo "Done."
