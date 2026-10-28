#!/usr/bin/env bash
# Moves the useful lines from your old ~/.zshrc into ~/dotfiles.
#   Rewrites (review with `git -C ~/dotfiles diff`):
#     zsh/zshrc      prompt_context/prompt_dir, gcloud, ~/.profile, no duplicate PATH
#     shell/path.sh  postgresql@16, ~/.local/bin, antigravity, VS Code `code`
#     shell/tools.sh ~/.rvm/bin
#   Appends once to ~/.shell_local (NOT in git):
#     secrets.env, workspace-nav.sh, rvm use ruby-4.0.5
set -euo pipefail

D="${DOTFILES:-$HOME/dotfiles}"
[ -d "$D/.git" ] || { echo "ERROR: $D is not the dotfiles repo"; exit 1; }

cat > "$D/zsh/zshrc" <<'DOTFILES_EOF'
# ~/.zshrc -> symlink to ~/dotfiles/zsh/zshrc

export DOTFILES="${DOTFILES:-$HOME/dotfiles}"
typeset -U path PATH   # zsh: never keep duplicate PATH entries

# Oh My Zsh, only if it's installed on this machine.
# Loaded BEFORE our aliases so ours win where names overlap
# (its git plugin also defines gst, gb, gf, glog...).
if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="agnoster"
  plugins=(git)
  [ -d "${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions" ] && plugins+=(zsh-autosuggestions)
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit && compinit
fi

# Lines installers add to ~/.profile (e.g. RVM). Read in sh mode.
[ -s "$HOME/.profile" ] && emulate sh -c '. "$HOME/.profile"'

# Google Cloud SDK (only if installed at this path)
_gcloud="$HOME/Downloads/google-cloud-sdk"
[ -f "$_gcloud/path.zsh.inc" ] && . "$_gcloud/path.zsh.inc"
[ -f "$_gcloud/completion.zsh.inc" ] && . "$_gcloud/completion.zsh.inc"
unset _gcloud

# Shared config: PATH, env, aliases, nvm/rvm, ~/.shell_local
[ -r "$DOTFILES/shell/init.sh" ] && source "$DOTFILES/shell/init.sh"

# ---------------- zsh-only ----------------

# agnoster prompt: show just "user" (no @hostname) ...
prompt_context() {
  local user=`whoami`
  if [[ "$user" != "root" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment magenta white " %(!.%{%F{black}%}.)$user "
  else
    prompt_segment red black " %(!.%{%F{black}%}.) $user "
  fi
}

# ... and just the current folder name instead of the full path
prompt_dir() {
  prompt_segment cyan black '%c'
}

# kubectl tab completion (works for the `kb` alias too)
command -v kubectl >/dev/null 2>&1 && source <(kubectl completion zsh)
DOTFILES_EOF
echo "updated zsh/zshrc"

cat > "$D/shell/path.sh" <<'DOTFILES_EOF'
# shellcheck shell=bash
# PATH setup. Each entry is added only if the folder exists on this
# machine, and never twice (safe to re-source).

path_prepend() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
}

path_append() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac
}

# Homebrew (Apple Silicon first, then Intel Mac)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Postgres 16 client tools (psql, pg_dump)
path_prepend "/opt/homebrew/opt/postgresql@16/bin"

# Make `python` point to Homebrew's python 3.9
path_prepend "/opt/homebrew/opt/python@3.9/libexec/bin"

# Personal and app CLIs
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"
path_append  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"   # `code`

# Docker Desktop CLI tools
path_append "$HOME/.docker/bin"

export PATH
DOTFILES_EOF
echo "updated shell/path.sh"

cat > "$D/shell/tools.sh" <<'DOTFILES_EOF'
# shellcheck shell=bash
# Version managers.

# NVM (Node)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# RVM (Ruby). Keep last: RVM warns if other tools are put before it in PATH.
path_prepend "$HOME/.rvm/bin"
[ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"
DOTFILES_EOF
echo "updated shell/tools.sh"

if grep -q "Moved from old ~/.zshrc" "$HOME/.shell_local" 2>/dev/null; then
  echo "skip    ~/.shell_local (already added)"
else
  cat >> "$HOME/.shell_local" <<'DOTFILES_EOF'

# ---- Moved from old ~/.zshrc (this Mac only) ----

# PosiWise build secrets (env file; stays out of git)
if [ -f "$HOME/Code/posiwise-build/tooling/secrets.env" ]; then
  set -a; . "$HOME/Code/posiwise-build/tooling/secrets.env"; set +a
fi

# PosiWise workspace navigation helpers (zsh only, as before)
if [ -n "$ZSH_VERSION" ]; then
  _nav="$HOME/Desktop/MyWorkspace/workspace/posiwise/projects/posiwise-build-agent-1/tooling/scripts/workspace-nav.sh"
  [ -f "$_nav" ] && . "$_nav"
  unset _nav
fi

# Default Ruby on this Mac
command -v rvm >/dev/null 2>&1 && rvm use ruby-4.0.5 --quiet 2>/dev/null
DOTFILES_EOF
  echo "updated ~/.shell_local"
fi

echo
echo "Done. Next:"
echo "  git -C \"$D\" diff      # review"
echo "  reload                   # try it"
echo "  dot_save \"chore: merge old zshrc\""
