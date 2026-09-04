#!/bin/bash
# Statusline: caveman mode badge on first line, YAS rows below.
# Both plugin paths resolved at runtime so version bumps do not break it.

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
input=$(cat)

caveman=$(ls -1 "$CFG"/plugins/cache/caveman/caveman/*/hooks/caveman-statusline.sh 2>/dev/null | head -1)
if [ -n "$caveman" ]; then
  badge=$(bash "$caveman" 2>/dev/null)
  [ -n "$badge" ] && printf '%s\n' "$badge"
fi

yas_root=$(ls -1d "$CFG"/plugins/cache/yet-another-statusline/yas/*/ 2>/dev/null | sort -V | tail -1)
if [ -n "$yas_root" ]; then
  yas_py=$(ls -1 "$yas_root".python/*/bin/python3.[0-9]* 2>/dev/null | head -1)
  [ -n "$yas_py" ] || yas_py=$(command -v python3)
  [ -n "$yas_py" ] && printf '%s' "$input" | "$yas_py" "${yas_root}claude/statusline_command.py"
fi

exit 0
