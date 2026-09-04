#!/bin/bash
# Set up Claude Code: CLI, global instructions, settings, plugins, statusline,
# and the Nerd Font the statusline draws with.
#
# Idempotent. Anything real it replaces is backed up next to the original.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
AGENTS_MD="${HOME}/.codex/AGENTS.md"
FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMonoNerd"
NERD_FONT="JetBrainsMono Nerd Font"
NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
YAS_INSTALLER="https://raw.githubusercontent.com/tmck-code/yet-another-statusline/main/ops/install.sh"

step() { echo; echo "==> $*"; }
info() { echo "    $*"; }

link() {
    local src="$1" dest="$2"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        info "$dest already linked"
        return
    fi
    mkdir -p "$(dirname "$dest")"
    if [ -e "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)"
        info "backed up $dest"
    fi
    ln -sfn "$src" "$dest"
    info "$dest -> $src"
}

step "Claude CLI"
if command -v claude >/dev/null 2>&1; then
    info "present: $(claude --version | head -n 1)"
else
    curl -fsSL https://claude.ai/install.sh | bash
    export PATH="${HOME}/.local/bin:${PATH}"
fi

step "Instructions"
link "${REPO_DIR}/CLAUDE.md" "${CLAUDE_DIR}/claude.md"      # coding guide
link "${REPO_DIR}/claude/AGENTS.md" "$AGENTS_MD"            # preferences, shared with Codex
printf '@%s\n' "$AGENTS_MD" > "${CLAUDE_DIR}/CLAUDE.md"     # Claude Code imports them
info "${CLAUDE_DIR}/CLAUDE.md imports $AGENTS_MD"

step "Skills"
for skill in "${REPO_DIR}"/claude/skills/*/; do
    link "${skill%/}" "${CLAUDE_DIR}/skills/$(basename "$skill")"
done

step "Plugins"
# caveman: compressed replies. yas: the statusline. The yas installer also
# provisions its Python, wires its prompt hook, and points statusLine at its own
# versioned path, so it has to run before the statusLine wiring below.
[ -d "${CLAUDE_DIR}/plugins/cache/caveman" ] || {
    claude plugin marketplace add JuliusBrussee/caveman
    claude plugin install caveman@caveman
}
[ -d "${CLAUDE_DIR}/plugins/cache/yet-another-statusline" ] || curl -fsSL "$YAS_INSTALLER" | YAS_NO_TTY=1 bash

step "Statusline"
# One statusLine command, two things to show: the wrapper prints the caveman
# mode badge, then hands stdin to yas. It resolves both plugin paths at runtime,
# so version bumps do not break it.
link "${REPO_DIR}/claude/statusline.sh" "${CLAUDE_DIR}/statusline.sh"
link "${REPO_DIR}/claude/yas.toml" "${CLAUDE_DIR}/yas.toml"

step "Settings"
# Merged, not symlinked: Claude Code writes plugin state into this file itself.
SETTINGS="${CLAUDE_DIR}/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
TMP="$(mktemp)"
jq --slurpfile base "${REPO_DIR}/claude/settings.base.json" \
   --arg cmd "bash \"${CLAUDE_DIR}/statusline.sh\"" \
   '. * $base[0] | .statusLine = {type: "command", command: $cmd, async: true, refreshInterval: 1, padding: 1}' \
   "$SETTINGS" > "$TMP"
mv "$TMP" "$SETTINGS"
info "merged claude/settings.base.json; statusLine -> ${CLAUDE_DIR}/statusline.sh"

step "Fonts"
# fc-list -q, not `fc-list | grep -q`: grep exits early, the pipe kills fc-list,
# and pipefail then reports the font missing on every run.
if ! fc-list -q "$NERD_FONT"; then
    TMP_DIR="$(mktemp -d)"
    curl -fsSL --retry 2 -o "${TMP_DIR}/font.zip" "$NERD_FONT_URL"
    unzip -o -j "${TMP_DIR}/font.zip" JetBrainsMonoNerdFont-{Regular,Bold,Italic,BoldItalic}.ttf -d "$FONT_DIR" >/dev/null
    rm -rf "$TMP_DIR"
    info "installed $NERD_FONT"
fi
# The conf serves the font as a fallback only, so the terminal keeps its own
# face; see the comments in it before editing.
link "${REPO_DIR}/claude/fontconfig/60-nerd-font-fallback.conf" \
     "${HOME}/.config/fontconfig/conf.d/60-nerd-font-fallback.conf"
fc-cache -f >/dev/null
info "font cache refreshed; restart every terminal window to pick it up"
