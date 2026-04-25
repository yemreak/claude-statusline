#!/usr/bin/env sh
# claude-statusline · uninstaller
# removes the statusLine key from ~/.claude/settings.json
# requires: jq

set -eu

GRN='\033[32m'
DIM='\033[2m'
RST='\033[0m'

ok()   { printf "%b✓%b %s\n" "$GRN" "$RST" "$1"; }
note() { printf "%b%s%b\n" "$DIM" "$1" "$RST"; }

command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

SETTINGS="${HOME}/.claude/settings.json"
[ -f "$SETTINGS" ] || { note "no settings.json · nothing to do"; exit 0; }

if ! jq -e '.statusLine' "$SETTINGS" >/dev/null 2>&1; then
  note "no statusLine key · nothing to do"
  exit 0
fi

STAMP=$(date +%Y%m%d-%H%M%S)
cp "$SETTINGS" "${SETTINGS}.bak.${STAMP}"
note "backup → ${SETTINGS}.bak.${STAMP}"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
jq 'del(.statusLine)' "$SETTINGS" > "$TMP"
mv "$TMP" "$SETTINGS"

ok "statusLine removed → ${SETTINGS}"
note "restart Claude Code"
