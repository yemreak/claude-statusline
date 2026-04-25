# claude-statusline

A rich Claude Code status line — model, context bar, token counters, session cost, and **5h + 7d rate-limit countdowns**.

![statusline-render](images/statusline-render.png)

> Left to right: model (Opus 4.7, 1M context), context bar (11% used), token counters (in:110K out:54K ctx:165K), session cost ($4.4439), 5-hour window (48% remaining, resets in 1h41m), 7-day window (93% remaining, resets in 161h21m).

The two countdowns on the right are the load-bearing piece — a percentage tells you a state, a countdown tells you when the state ends. That's what changes day-planning behavior.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/yemreak/claude-statusline/main/install.sh | sh
```

Restart Claude Code · the bar appears on the next turn.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/yemreak/claude-statusline/main/uninstall.sh | sh
```

## What it does

- merges a `statusLine` block into `~/.claude/settings.json`
- backs up the existing `statusLine` (if any) to `~/.claude/settings.json.bak.<timestamp>`
- atomic write (tmp → mv) · never leaves a half-written file
- idempotent · re-running just refreshes the block

## Requirements

- `jq` on `PATH` (macOS: `brew install jq` · linux: `apt-get install jq`)
- Claude Code CLI

## Anatomy of the bar

```
Opus 4.7 (1M context) │ ▓░░░░░░░░░ 11% │ in:110K out:54K ctx:165K │ $4.4439 │ 5h:48%(1h41m) │ 7d:93%(161h21m)
└── model ──────────┘ └── ctx-bar ───┘ └── token-counters ─────┘ └─cost─┘ └── 5h-window ─┘ └── 7d-window ──┘
```

- **model** · cyan
- **context bar** · 10-cell · green <70% · yellow 70-89% · red ≥90%
- **token counters** · `in:` = input + cache_creation + cache_read · `out:` = total output · `ctx:` = sum
- **cost** · session USD with 4 decimals (only when > 0)
- **5h / 7d window** · `<remaining-percent>%(<time-until-reset>)` · green >30% · yellow 11-30% · red ≤10%

The 5h and 7d segments only render on plans where Claude Code populates `rate_limits.five_hour` / `rate_limits.seven_day` (Pro / Max). API-only setups quietly leave them empty.

## License

MIT · see [LICENSE](LICENSE)
