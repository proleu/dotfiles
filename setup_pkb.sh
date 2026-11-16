#!/bin/bash
# Set up the personal knowledge base: an Obsidian vault in its own git repository.
#
# Idempotent. It copies a seed file only when the vault does not have that file,
# so it never overwrites a note or a setting. It never pushes.
#
# Environment:
#   PKB_DIR     Vault location. Default: ~/vault.
#   PKB_REMOTE  Git remote of the vault. If the vault does not exist, the script clones it.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_DIR="${REPO_DIR}/pkb/vault"
PKB_DIR="${PKB_DIR:-${HOME}/vault}"
PKB_REMOTE="${PKB_REMOTE:-}"

step() { echo; echo "==> $*"; }
info() { echo "    $*"; }

step "Vault"
if [ -d "${PKB_DIR}/.git" ]; then
    info "present: $PKB_DIR"
elif [ -n "$PKB_REMOTE" ] && [ ! -e "$PKB_DIR" ]; then
    git clone "$PKB_REMOTE" "$PKB_DIR"
else
    mkdir -p "$PKB_DIR"
    git -C "$PKB_DIR" init -b main >/dev/null
    info "initialized $PKB_DIR"
fi
if [ -n "$PKB_REMOTE" ] && ! git -C "$PKB_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$PKB_DIR" remote add origin "$PKB_REMOTE"
    info "origin -> $PKB_REMOTE"
fi

step "Seed files"
SEEDED=()
while IFS= read -r -d '' src; do
    rel="${src#"${SEED_DIR}/"}"
    dest="${PKB_DIR}/${rel}"
    [ -e "$dest" ] && continue
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    SEEDED+=("$rel")
    info "added $rel"
done < <(find "$SEED_DIR" -type f -print0 | sort -z)
[ "${#SEEDED[@]}" -gt 0 ] || info "nothing to add"

step "Commit"
# The commit holds only the files this run added. Work in progress in the vault stays as it is.
# commit.gpgsign=false: an automated commit must not be signed.
if [ "${#SEEDED[@]}" -eq 0 ]; then
    info "nothing to commit"
elif ! git -C "$PKB_DIR" config user.email >/dev/null; then
    info "git user.email is not set; commit the seed files manually"
else
    git -C "$PKB_DIR" add -- "${SEEDED[@]}"
    # A restored file that matches its committed version leaves nothing to commit.
    if git -C "$PKB_DIR" diff --cached --quiet -- "${SEEDED[@]}"; then
        info "nothing to commit"
    else
        git -C "$PKB_DIR" -c commit.gpgsign=false commit --quiet -m "Add vault seed files" -- "${SEEDED[@]}"
        info "committed ${#SEEDED[@]} files"
    fi
fi

step "Next"
info "Open Obsidian, select 'Open folder as vault', and select $PKB_DIR"
if ! git -C "$PKB_DIR" remote get-url origin >/dev/null 2>&1; then
    info "No remote. Create a private repository, then: git -C $PKB_DIR remote add origin <url>"
fi
