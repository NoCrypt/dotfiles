#!/usr/bin/env bash
# Keep the reference copies under etc/, usr/ and boot/ in sync with the live system.
#   status  diff repo vs system (read-only)
#   pull    copy system -> repo
#   push    copy repo -> system (sudo; backs up first)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="/var/backups/dotfiles-sync/$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0
COMMAND=""

# repo path | system path | pushable
# fstab is pull-only: pushing a stale fstab can make the machine unbootable.
MAPPINGS=(
    "etc/sddm.conf.d|/etc/sddm.conf.d|yes"
    "etc/default/grub|/etc/default/grub|yes"
    "etc/mkinitcpio.conf|/etc/mkinitcpio.conf|yes"
    "etc/systemd/zram-generator.conf.d|/etc/systemd/zram-generator.conf.d|yes"
    "etc/systemd/system/scx.service|/etc/systemd/system/scx.service|yes"
    "etc/xdg/reflector|/etc/xdg/reflector|yes"
    "etc/pacman.conf|/etc/pacman.conf|yes"
    "usr/share/sddm/scripts/Xsetup|/usr/share/sddm/scripts/Xsetup|yes"
    "usr/share/sddm/themes/orbital|/usr/share/sddm/themes/orbital|yes"
    "boot/grub/themes/ncpt|/boot/grub/themes/ncpt|yes"
    "etc/fstab|/etc/fstab|no"
)

# App-managed backups and merge leftovers never belong in the repo.
EXCLUDES=(--exclude='*.bak-*' --exclude='*.pacnew' --exclude='*.pacsave')
# rsync runs with -c: same-size edits with equal mtimes would otherwise be skipped.

usage() {
    printf 'usage: %s [--dry-run] {status|pull|push}\n' "${0##*/}"
    exit "${1:-0}"
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

has_diff() {
    ! diff -rq "${EXCLUDES[@]}" "$1" "$2" >/dev/null 2>&1
}

show_diff() {
    diff -ru "${EXCLUDES[@]}" "$1" "$2" || true
}

confirm() {
    local reply
    read -r -p "$1 [y/N] " reply
    [[ $reply == [yY] || $reply == [yY][eE][sS] ]]
}

pull_one() {
    local src="$REPO/$1" dst="$2"
    if [[ -d $dst ]]; then
        mkdir -p "$src"
        rsync -a -c "${EXCLUDES[@]}" "$dst"/ "$src"/
    else
        mkdir -p "$(dirname "$src")"
        rsync -a -c "$dst" "$src"
    fi
}

push_one() {
    local src="$REPO/$1" dst="$2" backup
    if [[ -e $dst ]]; then
        backup="$BACKUP_ROOT$dst"
        sudo mkdir -p "$(dirname "$backup")"
        sudo cp -a "$dst" "$backup"
        BACKED_UP=1
    fi
    if [[ -d $src ]]; then
        sudo mkdir -p "$dst"
        # Keep the system owner (root), only take mode/times/content from the repo.
        sudo rsync -a -c --no-owner --no-group "${EXCLUDES[@]}" "$src"/ "$dst"/
    else
        sudo mkdir -p "$(dirname "$dst")"
        sudo rsync -a -c --no-owner --no-group "$src" "$dst"
    fi
}

run_hook() {
    local prefix=running
    if [[ $DRY_RUN -eq 1 ]]; then prefix='would run'; fi
    printf '%s: %s\n' "$prefix" "$*"
    if [[ $DRY_RUN -eq 0 ]]; then "$@"; fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n) DRY_RUN=1 ;;
        status|pull|push)
            [[ -z $COMMAND ]] || usage 1
            COMMAND="$1"
            ;;
        -h|--help) usage ;;
        *) usage 1 ;;
    esac
    shift
done
COMMAND="${COMMAND:-status}"

if [[ $COMMAND != status ]]; then
    command -v rsync >/dev/null 2>&1 || die "rsync is required"
fi
if [[ $COMMAND == push && $DRY_RUN -eq 0 ]]; then
    command -v sudo >/dev/null 2>&1 || die "sudo is required for push"
fi

if [[ $COMMAND == status ]]; then
    found=0
    for mapping in "${MAPPINGS[@]}"; do
        IFS='|' read -r src dst _ <<<"$mapping"
        if [[ ! -e $REPO/$src && ! -e $dst ]]; then
            printf 'missing on both sides: %s\n' "$src"
            found=1
        elif [[ ! -e $REPO/$src ]]; then
            printf 'only on system: %s\n' "$dst"
            found=1
        elif [[ ! -e $dst ]]; then
            printf 'only in repo: %s\n' "$src"
            found=1
        elif has_diff "$REPO/$src" "$dst"; then
            printf '\n=== %s (repo: %s)\n' "$dst" "$src"
            show_diff "$REPO/$src" "$dst"
            found=1
        fi
    done
    if [[ $found -eq 0 ]]; then printf 'all mapped files are in sync\n'; fi
    exit 0
fi

# Collect first so each diff is shown once and one confirmation covers everything.
CHANGED=()
GRUB_CHANGED=0
INITRAMFS_CHANGED=0
for mapping in "${MAPPINGS[@]}"; do
    IFS='|' read -r src dst mode <<<"$mapping"
    if [[ $COMMAND == push ]]; then
        [[ $mode == yes ]] || continue
        [[ -e $REPO/$src ]] || continue
        if [[ ! -e $dst ]] || has_diff "$REPO/$src" "$dst"; then
            CHANGED+=("$mapping")
            case "$src" in
                etc/default/grub|boot/grub/*) GRUB_CHANGED=1 ;;
                etc/mkinitcpio.conf) INITRAMFS_CHANGED=1 ;;
            esac
        fi
    else
        [[ -e $dst ]] || continue
        if [[ ! -e $REPO/$src ]] || has_diff "$REPO/$src" "$dst"; then
            CHANGED+=("$mapping")
        fi
    fi
done

if [[ ${#CHANGED[@]} -eq 0 ]]; then
    printf 'nothing to %s; everything is in sync\n' "$COMMAND"
    exit 0
fi

printf '\nDifferences to %s:\n' "$COMMAND"
for mapping in "${CHANGED[@]}"; do
    IFS='|' read -r src dst _ <<<"$mapping"
    printf '\n=== %s\n' "$src"
    if [[ ! -e $REPO/$src ]]; then
        printf '(not in repo yet: %s)\n' "$dst"
    elif [[ ! -e $dst ]]; then
        printf '(not on the system yet: %s)\n' "$dst"
    else
        show_diff "$REPO/$src" "$dst"
    fi
done

if [[ $DRY_RUN -eq 1 ]]; then
    if [[ $COMMAND == push ]]; then
        if [[ $GRUB_CHANGED -eq 1 ]]; then
            run_hook sudo grub-mkconfig -o /boot/grub/grub.cfg
        fi
        if [[ $INITRAMFS_CHANGED -eq 1 ]]; then
            run_hook sudo mkinitcpio -P
        fi
    fi
    printf '\n(dry-run: nothing copied)\n'
    exit 0
fi

confirm "Apply these changes?" || exit 1

BACKED_UP=0
for mapping in "${CHANGED[@]}"; do
    IFS='|' read -r src dst _ <<<"$mapping"
    if [[ $COMMAND == pull ]]; then
        pull_one "$src" "$dst"
    else
        push_one "$src" "$dst"
    fi
done

if [[ $COMMAND == push ]]; then
    if [[ $BACKED_UP -eq 1 ]]; then printf 'backups: %s\n' "$BACKUP_ROOT"; fi
    if [[ $GRUB_CHANGED -eq 1 ]]; then
        run_hook sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
    if [[ $INITRAMFS_CHANGED -eq 1 ]]; then
        run_hook sudo mkinitcpio -P
    fi
fi
