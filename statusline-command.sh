#!/bin/sh
# Claude Code status line - flat pipe-separated style

input=$(cat)

folder=$(echo "$input" | python3 -c '
import sys, json, os
d = json.load(sys.stdin)
cwd = d.get("workspace", {}).get("current_dir") or d.get("cwd", "")
home = os.path.expanduser("~")
print("~" if cwd == home else "~/" + os.path.basename(cwd))
' 2>/dev/null)

model=$(echo "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(d.get("model", {}).get("display_name", "Claude"))
' 2>/dev/null)

pct=$(echo "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(int(d.get("context_window", {}).get("used_percentage", 0)))
' 2>/dev/null)
pct=${pct:-0}

cost=$(echo "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
c = d.get("cost", {}).get("total_cost_usd", 0)
print(f"${c:.2f}")
' 2>/dev/null)
cost=${cost:-'$0.00'}

rl5h=$(echo "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(int(d.get("rate_limits", {}).get("five_hour", {}).get("used_percentage", 0)))
' 2>/dev/null)
rl5h=${rl5h:-0}

reset5h=$(echo "$input" | python3 -c '
import sys, json, time, datetime
d = json.load(sys.stdin)
resets_at = d.get("rate_limits", {}).get("five_hour", {}).get("resets_at", 0)
if not resets_at:
    print("")
else:
    secs = max(0, int(resets_at - time.time()))
    h, m = divmod(secs // 60, 60)
    rel = f"{h}h{m}m" if h else f"{m}m"
    exact = datetime.datetime.fromtimestamp(resets_at).strftime("%H:%M")
    print(f"{rel} {exact}")
' 2>/dev/null)
reset5h=${reset5h:-""}

rl7d=$(echo "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
print(int(d.get("rate_limits", {}).get("seven_day", {}).get("used_percentage", 0)))
' 2>/dev/null)
rl7d=${rl7d:-0}

reset7d=$(echo "$input" | python3 -c '
import sys, json, time, datetime
d = json.load(sys.stdin)
resets_at = d.get("rate_limits", {}).get("seven_day", {}).get("resets_at", 0)
if not resets_at:
    print("")
else:
    secs = max(0, int(resets_at - time.time()))
    h, rem = divmod(secs // 60, 60)
    d2 = h // 24
    rel = f"{d2}d{h%24}h" if d2 else f"{h}h{rem}m" if h else f"{rem}m"
    exact = datetime.datetime.fromtimestamp(resets_at).strftime("%H:%M")
    print(f"{rel} {exact}")
' 2>/dev/null)
reset7d=${reset7d:-""}

# Build a color-coded mini bar (8 chars) for a given percentage
make_bar() {
  val=$1
  python3 -c "
import sys
val = $val
filled = round(val / 100 * 8)
if val >= 80:
    clr = '\033[31m'
elif val >= 50:
    clr = '\033[33m'
else:
    clr = '\033[92m'
sys.stdout.write(clr + '█' * filled + '\033[90m' + '░' * (8 - filled) + '\033[0m')
" 2>/dev/null
}

# Context bar: 15 chars, green filled / dim empty
ctx_bar=$(python3 -c "
import sys
pct = $pct
filled = round(pct / 100 * 15)
sys.stdout.write('\033[92m' + '█' * filled + '\033[90m' + '░' * (15 - filled) + '\033[0m')
" 2>/dev/null)

bar5h=$(make_bar "$rl5h")
bar7d=$(make_bar "$rl7d")

# Percentage color for context: green <50%, yellow 50-70%, red >=70%
if [ "$pct" -ge 70 ]; then
    pct_clr="\033[31m"
elif [ "$pct" -ge 50 ]; then
    pct_clr="\033[33m"
else
    pct_clr="\033[92m"
fi

sep=" \033[90m|\033[0m "

printf "📂 \033[97m%s\033[0m${sep}★ \033[96m%s\033[0m${sep}\033[90mContext:\033[0m %s${pct_clr}%s%%\033[0m${sep}💰 \033[93mCost:%s\033[0m${sep}\033[90m5h\033[0m %s\033[97m%s%%\033[0m \033[90m↺%s\033[0m${sep}\033[90m7d\033[0m %s\033[97m%s%%\033[0m \033[90m↺%s\033[0m" \
  "$folder" "$model" "$ctx_bar" "$pct" "$cost" "$bar5h" "$rl5h" "$reset5h" "$bar7d" "$rl7d" "$reset7d"
