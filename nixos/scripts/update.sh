#!/usr/bin/env bash
set -uo pipefail

# where your flake lives
FLAKE_DIR="${FLAKE_DIR:-$HOME/git/dotfiles/nixos}"
REPO_DIR="${REPO_DIR:-$HOME/git/dotfiles}"

c_bold="\033[1m"
c_dim="\033[2m"
c_reset="\033[0m"

log() { echo -e "${c_bold}==>${c_reset} $1"; }
dim() { echo -e "${c_dim}$1${c_reset}"; }

cd "$FLAKE_DIR" || {
  echo "couldn't cd into $FLAKE_DIR"
  exit 1
}

log "updating flake inputs"
nix flake update

echo
log "changes in flake.lock:"
git -C "$REPO_DIR" diff --stat flake.lock 2>/dev/null || dim "  (no diff, or flake.lock not tracked yet)"
echo

log "rebuilding nixos config"
if ! nh os switch ~/git/dotfiles/nixos; then
  echo
  echo "rebuild failed."
  read -rp "continue to commit anyway? [y/N] " keep_going
  if [[ ! "$keep_going" =~ ^[Yy]$ ]]; then
    log "stopping here. flake.lock changes are still staged locally, nothing pushed."
    exit 1
  fi
fi

echo
log "rebuild finished"

read -rp "upload changes to github? [y/N] " do_push
if [[ ! "$do_push" =~ ^[Yy]$ ]]; then
  log "skipping git push. done."
  exit 0
fi

cd "$REPO_DIR" || {
  echo "couldn't cd into $REPO_DIR"
  exit 1
}

git add -A

if git diff --cached --quiet; then
  log "nothing to commit. done."
  exit 0
fi

default_msg="update flake inputs $(date +%Y-%m-%d)"
read -rp "commit message [default: ${default_msg}]: " commit_msg
commit_msg="${commit_msg:-$default_msg}"

git commit -m "$commit_msg"

log "pushing to github"
git push

log "done."
