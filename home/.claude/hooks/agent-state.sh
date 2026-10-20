#!/bin/sh
# Grava o estado da sessão do Claude Code para o Waybar (~/.config/waybar/scripts/agents.py).
# Uso (hooks em ~/.claude/settings.json): agent-state.sh idle|working|blocked|end
state="$1"
dir="$HOME/.cache/agent-status/claude-state"
sid=$(jq -r '.session_id // empty' 2>/dev/null)
[ -z "$sid" ] && exit 0
mkdir -p "$dir"
if [ "$state" = "end" ]; then
    rm -f "$dir/$sid.json"
    exit 0
fi
# PID do processo do Claude Code (sobe na árvore de processos a partir do hook)
pid=$PPID
while [ "$pid" -gt 1 ] && [ "$(cat /proc/$pid/comm 2>/dev/null)" != "claude" ]; do
    pid=$(sed 's/.*) //' /proc/$pid/stat 2>/dev/null | cut -d' ' -f2)
    [ -z "$pid" ] && pid=1
done
printf '{"state":"%s","pid":%s,"t":%s}\n' "$state" "$pid" "$(date +%s)" > "$dir/$sid.json.tmp" \
    && mv "$dir/$sid.json.tmp" "$dir/$sid.json"
exit 0
