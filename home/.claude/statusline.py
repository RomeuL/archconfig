#!/usr/bin/env python3
"""Status line do Claude Code.

Guarda o JSON que o Claude Code envia (contexto, limites de uso) em
~/.cache/agent-status/claude/<sessão>.json para o tooltip do Waybar
(~/.config/waybar/scripts/agents.py) e imprime uma linha curta.
"""
import json
import os
import sys
import time

data = json.load(sys.stdin)

# PID do processo do Claude Code, para o Waybar saber se a sessão ainda está aberta
pid = os.getppid()
while pid > 1:
    try:
        with open(f"/proc/{pid}/comm") as f:
            if f.read().strip() == "claude":
                break
        with open(f"/proc/{pid}/stat") as f:
            pid = int(f.read().rsplit(")", 1)[1].split()[1])
    except (OSError, ValueError, IndexError):
        pid = 0
        break
data["_pid"] = pid
data["_updated"] = time.time()

cache = os.path.expanduser("~/.cache/agent-status/claude")
os.makedirs(cache, exist_ok=True)
path = os.path.join(cache, f"{data.get('session_id', 'unknown')}.json")
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f)
os.replace(tmp, path)

parts = [data.get("model", {}).get("display_name", "Claude")]
ctx = (data.get("context_window") or {}).get("used_percentage")
if ctx is not None:
    parts.append(f"ctx {ctx:.0f}%")
limits = data.get("rate_limits") or {}
if "five_hour" in limits:
    parts.append(f"5h {limits['five_hour']['used_percentage']:.0f}%")
if "seven_day" in limits:
    parts.append(f"semana {limits['seven_day']['used_percentage']:.0f}%")
print(" · ".join(parts))
