#!/usr/bin/env sh
# claude-statusline · installer
# adds a rich statusLine block to ~/.claude/settings.json
# idempotent · backs up the existing statusLine before overwriting
# requires: jq

set -eu

RED='\033[31m'
GRN='\033[32m'
DIM='\033[2m'
RST='\033[0m'

ok()   { printf "%b✓%b %s\n" "$GRN" "$RST" "$1"; }
err()  { printf "%b✗%b %s\n" "$RED" "$RST" "$1" >&2; exit 1; }
note() { printf "%b%s%b\n" "$DIM" "$1" "$RST"; }

# ── 1. require jq ────────────────────────────────────────────────────
command -v jq >/dev/null 2>&1 || err "jq required. macOS: brew install jq · linux: apt-get install jq"

# ── 2. ensure settings file ──────────────────────────────────────────
SETTINGS="${HOME}/.claude/settings.json"
mkdir -p "${HOME}/.claude"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# ── 3. statusLine command (literal jq one-liner) ─────────────────────
# heredoc with quoted marker · zero shell expansion · preserved as-is
STATUSLINE_CMD=$(cat <<'JQ_PROGRAM'
jq -r 'def R:"\u001b[0m";def D:"\u001b[2m";def G:"\u001b[32m";def Y:"\u001b[33m";def X:"\u001b[31m";def C:"\u001b[36m";def W:"\u001b[37m";def ft($n):if $n>=1000000 then((($n/100000|floor)/10)|tostring)+"M" elif $n>=1000 then($n/1000|floor|tostring)+"K" else($n|tostring)end;def fd($s):if $s>=3600 then($s/3600|floor|tostring)+"h"+((($s%3600)/60|floor)|tostring)+"m" elif $s>=60 then($s/60|floor|tostring)+"m" else($s|tostring)+"s"end;def dec4($n):($n*10000|round)as $c|(($c/10000)|floor)as $w|($c-$w*10000)as $f|($w|tostring)+"."+(if $f<10 then "000"+($f|tostring) elif $f<100 then "00"+($f|tostring) elif $f<1000 then "0"+($f|tostring) else($f|tostring)end);def bar($p):(if $p>100 then 100 elif $p<0 then 0 else $p end|round)as $i|(if $i>=90 then X elif $i>=70 then Y else G end)as $c|($i*10/100|floor)as $f|(10-$f)as $e|$c+("▓"*$f//"")+D+("░"*$e//"")+R+" "+$c+($i|tostring)+"%"+R;def rl($o;$l):if $o.used_percentage==null then empty else(100-($o.used_percentage|round))as $m|(if $m<=10 then X elif $m<=30 then Y else G end)as $c|D+$l+":"+R+$c+($m|tostring)+"%"+R+(if $o.resets_at then((($o.resets_at|if type=="number" then . else fromdateiso8601 end)-now)|floor)as $d|(if $d>0 then D+"("+fd($d)+")"+R else "" end) else "" end)end;. as $j|($j.rate_limits.five_hour//{})as $h5|($j.rate_limits.seven_day//{})as $h7|[(if $j.model.display_name then C+$j.model.display_name+R else empty end),(if $j.context_window.used_percentage then bar($j.context_window.used_percentage) else empty end),(($j.context_window.current_usage//{})as $u|(($u.input_tokens//0)+($u.cache_creation_input_tokens//0)+($u.cache_read_input_tokens//0))as $in|($j.context_window.total_output_tokens//0)as $out|($in+$out)as $ctx|if $ctx>0 then D+"in:"+R+W+ft($in)+R+" "+D+"out:"+R+W+ft($out)+R+" "+D+"ctx:"+R+W+ft($ctx)+R else empty end),(if($j.cost.total_cost_usd//0)>0 then W+"$"+dec4($j.cost.total_cost_usd)+R else empty end),rl($h5;"5h")]+(if $h5.used_percentage!=null and $h7.used_percentage!=null then[rl($h7;"7d")]else[]end)|join(" "+D+"|"+R+" ")'
JQ_PROGRAM
)

# ── 4. backup existing statusLine if present ─────────────────────────
if jq -e '.statusLine' "$SETTINGS" >/dev/null 2>&1; then
  STAMP=$(date +%Y%m%d-%H%M%S)
  cp "$SETTINGS" "${SETTINGS}.bak.${STAMP}"
  note "backup → ${SETTINGS}.bak.${STAMP}"
fi

# ── 5. atomic merge ──────────────────────────────────────────────────
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
jq --arg cmd "$STATUSLINE_CMD" '.statusLine = {type:"command", command:$cmd}' "$SETTINGS" > "$TMP"
mv "$TMP" "$SETTINGS"

ok  "statusline installed → ${SETTINGS}"
note "restart Claude Code · the bar appears on the next turn"
