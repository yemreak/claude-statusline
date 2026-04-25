#!/usr/bin/env sh
# claude-statusline · uninstaller
# removes the statusLine key from a Claude Code settings.json
#
#   default          ./.claude/settings.json   (project-local · cwd)
#   -g | --global    ~/.claude/settings.json   (user-global)
#
# requires: jq

set -eu

GRN='\033[32m'
DIM='\033[2m'
RST='\033[0m'

ok()    { printf "%b✓%b %s\n" "$GRN" "$RST" "$1"; }
note()  { printf "%b%s%b\n" "$DIM" "$1" "$RST"; }
usage() { printf "usage: uninstall.sh [-g|--global]\n" >&2; exit 2; }

SCOPE=local
case "${1-}" in
  ""             ) SCOPE=local  ;;
  -g|--global    ) SCOPE=global ;;
  -h|--help      ) usage        ;;
  *              ) usage        ;;
esac

command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }

if [ "$SCOPE" = global ]; then
  SETTINGS="${HOME}/.claude/settings.json"
else
  SETTINGS="$(pwd)/.claude/settings.json"
fi

[ -f "$SETTINGS" ] || { note "no settings.json at ${SETTINGS} · nothing to do"; exit 0; }

if ! jq -e '.statusLine' "$SETTINGS" >/dev/null 2>&1; then
  note "no statusLine key in ${SETTINGS} · nothing to do"
  exit 0
fi

STAMP=$(date +%Y%m%d-%H%M%S)
cp "$SETTINGS" "${SETTINGS}.bak.${STAMP}"
note "backup → ${SETTINGS}.bak.${STAMP}"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
jq 'del(.statusLine)' "$SETTINGS" > "$TMP"
mv "$TMP" "$SETTINGS"

ok   "statusLine removed → ${SETTINGS}  (scope: ${SCOPE})"
note "restart Claude Code"
