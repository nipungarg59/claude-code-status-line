# claude-code-status-line

A Claude Code status line showing folder, model, context window, session cost, and plan rate limits — all color-coded, updated on every response.

## Preview

```
📂 ~/my-project | ★ Sonnet 4.6 | Context: ████░░░░░░░░░░░ 25% | 💰 Cost:$0.63 | 5h ███░░░░░ 42% ↺18m | 7d █░░░░░░░ 17% ↺3d23h
```

**Segments:**
- `📂 ~/project` — current folder
- `★ Model` — active Claude model
- `Context: [bar] %` — context window usage (green <50%, yellow 50–70%, red ≥70%)
- `💰 Cost:$X.XX` — cumulative session cost in USD
- `5h [bar] % ↺Xm` — 5-hour rate limit usage + time until reset
- `7d [bar] % ↺XdXh` — 7-day rate limit usage + time until reset

Rate limit bars: green <50%, yellow 50–80%, red ≥80%.

> Requires a terminal with color support. Nerd Font not required.

## Install

**1. Copy the script:**
```bash
curl -o ~/.claude/statusline-command.sh \
  https://raw.githubusercontent.com/nipungarg59/claude-code-status-line/main/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

**2. Add to `~/.claude/settings.json`:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.claude/statusline-command.sh"
  }
}
```

If `settings.json` already has other keys, merge — don't replace the whole file.

**3. Restart Claude Code.** The status line appears at the bottom of the terminal UI immediately.

## Requirements

- Claude Code CLI
- Python 3 (used for JSON parsing and time calculation — pre-installed on macOS/Linux)
- No external dependencies

## How it works

Claude Code passes a JSON blob to the status line command on stdin each time it updates. The script extracts:

| Field | JSON path |
|---|---|
| Current directory | `workspace.current_dir` |
| Model name | `model.display_name` |
| Context usage | `context_window.used_percentage` |
| Session cost | `cost.total_cost_usd` |
| 5h rate limit | `rate_limits.five_hour.used_percentage` / `resets_at` |
| 7d rate limit | `rate_limits.seven_day.used_percentage` / `resets_at` |

## Customization

- **Bar width:** change the `15` (context) or `8` (rate limits) in the script
- **Color thresholds:** adjust the `>= 70` / `>= 50` / `>= 80` comparisons
- **Segments:** remove any `${sep}...` block from the final `printf` line
