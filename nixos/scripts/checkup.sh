#!/usr/bin/env bash
set -uo pipefail

c_bold="\033[1m"
c_dim="\033[2m"
c_reset="\033[0m"

log() { echo -e "${c_bold}==>${c_reset} $1"; }
dim() { echo -e "${c_dim}$1${c_reset}"; }

echo -e "${c_bold}nixos health check${c_reset}"
dim "$(date)"
echo

# disk usage
log "disk usage"
df -h / /nix 2>/dev/null | grep -v "^tmpfs"
echo
dim "store size: $(du -sh /nix/store 2>/dev/null | cut -f1)"
echo

# generation count
log "system generations"
gen_count=$(nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l)
echo "  $gen_count generations present"
if ((gen_count > 15)); then
  dim "  (getting up there — consider a deep clean)"
fi
echo

# failed units
log "failed systemd units"
failed=$(systemctl --failed --no-legend --no-pager)
if [[ -z "$failed" ]]; then
  dim "  none"
else
  echo "$failed"
fi
echo

# journal size
log "journal size"
journalctl --disk-usage 2>/dev/null | sed 's/^/  /'
echo

# stale result symlinks (common gc-root leak from ad-hoc nix build)
log "stale 'result' symlinks under home"
stale_results=$(find "$HOME" -maxdepth 4 -type l -name "result*" 2>/dev/null)
if [[ -z "$stale_results" ]]; then
  dim "  none found"
else
  echo "$stale_results" | sed 's/^/  /'
fi
echo

if [[ "${1:-}" != "--clean" ]]; then
  dim "run with --clean to garbage-collect, optimise the store, and vacuum the journal"
  exit 0
fi

echo
log "deep clean starting"

log "collecting garbage older than 14 days"
sudo nix-collect-garbage --delete-older-than 14d

log "optimising store (hardlinking duplicate files)"
sudo nix-store --optimise

log "vacuuming journal to 7 days"
sudo journalctl --vacuum-time=7d

echo
log "deep clean finished"
dim "store size now: $(du -sh /nix/store 2>/dev/null | cut -f1)"
