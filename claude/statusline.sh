#!/bin/bash
# Statusline: YAS rows. The plugin path is resolved at runtime so version bumps do not break it.

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
input=$(cat)

yas_root=$(ls -1d "$CFG"/plugins/cache/yet-another-statusline/yas/*/ 2>/dev/null | sort -V | tail -1)
if [ -n "$yas_root" ]; then
  yas_py=$(ls -1 "$yas_root".python/*/bin/python3.[0-9]* 2>/dev/null | head -1)
  [ -n "$yas_py" ] || yas_py=$(command -v python3)
  [ -n "$yas_py" ] && printf '%s' "$input" | "$yas_py" "${yas_root}claude/statusline_command.py"
fi

exit 0
