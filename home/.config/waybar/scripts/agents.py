#!/usr/bin/env python3
"""Status de todas as sessões do Claude Code e do Codex abertas, para o Waybar.

Sem argumentos: escuta os eventos do Hyprland e imprime uma linha JSON a cada mudança.
Com "focus": foca a próxima janela de agente (usado no clique do módulo).
Um último argumento "claude" ou "codex" limita a um só agente (um módulo para cada).
Com "daemon": um único processo para todas as barras; grava o estado de cada agente em
~/.cache/agent-status/waybar-<agente>.json e os módulos só fazem `tail -F` desses arquivos.
Na barra: limite de 5h e contexto da sessão atualizada mais recentemente de cada agente.

O estado vem de duas fontes:
  1. Sessões reais (funciona mesmo com o agente numa aba de trás do terminal):
     Claude Code  hooks gravam ~/.cache/agent-status/claude-state/<sessão>.json
                  (~/.claude/hooks/agent-state.sh); sessões sem hook ainda vêm do cache da status line
     Codex        task_started/task_complete nos arquivos de sessão abertos em ~/.codex/sessions
  2. Título das janelas visíveis (instantâneo, com spinner, e permite focar a janela no clique):
     Claude Code  "<ícone> <sessão>"   ✳ parado, outros ícones = trabalhando
     Codex        "Ready" parado; Working/Thinking/Starting/Waiting ou spinner = trabalhando
                  texto de aprovação = bloqueado
"""
import glob
import html
import json
import locale
import os
import re
import socket
import subprocess
import sys
import time
import fcntl

try:  # dias da semana em português no tooltip
    locale.setlocale(locale.LC_TIME, "pt_BR.UTF-8")
except locale.Error:
    pass

CLAUDE = re.compile(r"^([✳✢✶✻✽·◐◓◑◒]) (.*)$")
CODEX_BLOCKED = re.compile(
    r"^(?:\[\s*[!.]\s*\]\s*)?(?:Action required|Approval needed|Waiting for approval)\b",
    re.I,
)
CODEX_WORKING = {"Working", "Thinking", "Starting", "Waiting"}
CODEX_SPINNER = re.compile(r"^[^\x00-\x7f\s]{1,2}$")  # título só com o spinner (não-ASCII, para não pegar "~")

CLAUDE_ORANGE = "#ff8a3d"  # cor da marca do Claude; as outras vêm do tema atual
PALETTE = os.path.expanduser("~/.config/theme/current/palette.json")  # gravado pelo theme-set
_palette = {"mtime": None, "colors": {}}
CODEX_IDLE = "󰚩"
BLOCKED = "󰀦"

CLAUDE_CACHE = os.path.expanduser("~/.cache/agent-status/claude")  # gravado por ~/.claude/statusline.py
CLAUDE_STATE = os.path.expanduser("~/.cache/agent-status/claude-state")  # gravado pelos hooks
CODEX_SESSIONS = os.path.expanduser("~/.codex/sessions")
REFRESH = 2  # segundos entre atualizações (estado de abas em segundo plano e uso), além dos eventos
CLAUDE_WORKING = "◐"  # ícone de sessão do Claude trabalhando numa aba que não está visível
STATE_DIR = os.path.expanduser("~/.cache/agent-status")


def clients():
    out = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True).stdout
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return []


def classify(title):
    """Retorna (agente, estado, ícone) ou None se a janela não é de um agente."""
    title = title.strip()
    m = CLAUDE.match(title)
    if m:
        state = "idle" if m.group(1) == "✳" else "working"
        return "claude", state, m.group(1)
    if title == "Ready":
        return "codex", "idle", CODEX_IDLE
    if CODEX_BLOCKED.match(title) or title in {"Needs input", "Blocked"}:
        return "codex", "blocked", BLOCKED
    if title in CODEX_WORKING:
        return "codex", "working", CODEX_IDLE
    if CODEX_SPINNER.match(title):
        return "codex", "working", title
    return None


def claude_session_states():
    """Estado de cada processo aberto do Claude Code (um processo = uma sessão ativa):
    dos hooks, ou "idle" se só existe o cache da status line (sessão aberta antes dos hooks)."""
    by_pid = {}
    for path in glob.glob(os.path.join(CLAUDE_CACHE, "*.json")):
        try:
            with open(path) as f:
                d = json.load(f)
        except (OSError, json.JSONDecodeError):
            continue
        pid = d.get("_pid", 0)
        if pid_alive(pid, "claude"):
            by_pid.setdefault(pid, (0, "idle"))
    for path in glob.glob(os.path.join(CLAUDE_STATE, "*.json")):
        try:
            with open(path) as f:
                d = json.load(f)
        except (OSError, json.JSONDecodeError):
            continue
        pid = d.get("pid", 0)
        if pid_alive(pid, "claude") and d.get("t", 0) >= by_pid.get(pid, (0, ""))[0]:
            by_pid[pid] = (d.get("t", 0), d.get("state", "idle"))
    return [state for _, state in by_pid.values()]


def codex_session_states():
    """Estado de cada sessão aberta do Codex pelo último task_started/task_complete."""
    states = []
    for path in codex_open_rollouts():
        try:
            with open(path, "rb") as f:
                f.seek(0, os.SEEK_END)
                f.seek(max(0, f.tell() - 500_000))
                tail = f.read().decode(errors="replace")
        except OSError:
            continue
        started, completed = tail.rfind('"task_started"'), tail.rfind('"task_complete"')
        states.append("working" if started > completed else "idle")
    return states


def agents(only=None):
    found = []
    for c in clients():
        info = classify(c.get("title", ""))
        if info and (only is None or info[0] == only):
            ws = c.get("workspace", {}).get("name", "")
            found.append((ws, c["at"][0], c["address"], c["title"], *info))
    # Sessões que não têm janela visível (ex.: numa aba de trás) entram pelo estado real da sessão
    for agent, states in (("claude", claude_session_states), ("codex", codex_session_states)):
        if only not in (None, agent):
            continue
        hidden = states()
        for f in found:  # cada janela visível já representa uma sessão
            if f[4] == agent and hidden:
                hidden.remove(f[5] if f[5] in hidden else hidden[0])
        for state in hidden:
            if agent == "claude":
                icon = BLOCKED if state == "blocked" else "✳" if state == "idle" else CLAUDE_WORKING
            else:
                icon = BLOCKED if state == "blocked" else CODEX_IDLE
            found.append(("~", 0, None, "", agent, state, icon))
    found.sort(key=lambda f: (f[0], f[1]))
    return found


# ---------- uso de tokens e limites ----------

def fmt_tokens(n):
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M".replace(".0M", "M")
    if n >= 1000:
        return f"{n / 1000:.0f}k"
    return str(n)


def fmt_reset(epoch):
    t = time.localtime(epoch)
    day = time.strftime("%Y%m%d", t)
    if day == time.strftime("%Y%m%d"):
        return time.strftime("%H:%M", t)
    if day == time.strftime("%Y%m%d", time.localtime(time.time() + 86400)):
        return time.strftime("amanhã %H:%M", t)
    return time.strftime("%a %H:%M", t)


def theme(name, fallback):
    """Cor do tema atual (relida quando o theme-set troca o tema)."""
    try:
        mtime = os.stat(PALETTE).st_mtime
        if mtime != _palette["mtime"]:
            with open(PALETTE) as f:
                _palette.update(mtime=mtime, colors=json.load(f)["colors"])
    except (OSError, ValueError, KeyError):
        pass
    return _palette["colors"].get(name, fallback)


def agent_color(agent):
    return CLAUDE_ORANGE if agent == "claude" else theme("active", "#00f0ff")


def level_color(pct):
    if pct >= 80:
        return theme("red", "#ff003c")
    return theme("yellow", "#fcee09") if pct >= 50 else theme("green", "#00ff9c")


def bar(pct, width=10):
    filled = round(max(0, min(100, pct)) / 100 * width)
    color = level_color(pct)
    done = f"<span color='{color}'>{'▰' * filled}</span>" if filled else ""
    rest = f"<span color='{theme('muted', '#2a2a2a')}'>{'▱' * (width - filled)}</span>" if filled < width else ""
    return done + rest


def limit_line(label, used, resets_at):
    return (f"  {label:<7}{bar(used)} {used:>3.0f}% usado · restam {100 - used:.0f}%"
            f" <span color='{theme('dark_foreground', '#7a7a7a')}'>(reseta {fmt_reset(resets_at)})</span>")


def short_dir(path):
    home = os.path.expanduser("~")
    return "~" + path[len(home):] if path and path.startswith(home) else (path or "?")


def pid_alive(pid, name):
    try:
        with open(f"/proc/{pid}/comm") as f:
            return f.read().strip() == name
    except OSError:
        return False


def claude_usage():
    """Sessões abertas do Claude Code, a partir do cache da status line."""
    sessions = []
    for path in glob.glob(os.path.join(CLAUDE_CACHE, "*.json")):
        try:
            with open(path) as f:
                d = json.load(f)
        except (OSError, json.JSONDecodeError):
            continue
        if not pid_alive(d.get("_pid", 0), "claude"):
            continue
        sessions.append(d)
    sessions.sort(key=lambda d: d.get("_updated", 0), reverse=True)
    return sessions


def codex_open_rollouts():
    """Arquivos de sessão que algum processo do Codex mantém abertos."""
    files = set()
    for pid in os.listdir("/proc"):
        if not pid.isdigit() or not pid_alive(pid, "codex"):
            continue
        try:
            for fd in os.listdir(f"/proc/{pid}/fd"):
                target = os.readlink(f"/proc/{pid}/fd/{fd}")
                if target.startswith(CODEX_SESSIONS) and target.endswith(".jsonl"):
                    files.add(target)
        except OSError:
            continue
    return files


def codex_usage():
    """Último uso de tokens, limites e modelo de cada sessão aberta do Codex."""
    sessions = []
    for path in codex_open_rollouts():
        try:
            with open(path, "rb") as f:
                f.seek(0, os.SEEK_END)
                f.seek(max(0, f.tell() - 2_000_000))
                lines = f.read().decode(errors="replace").splitlines()
        except OSError:
            continue
        s = {"_updated": os.path.getmtime(path)}
        for line in reversed(lines):
            if "token_count" not in line and "turn_context" not in line:
                continue
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            p = ev.get("payload", {})
            if ev.get("type") == "turn_context" and "model" not in s:
                s["model"], s["effort"], s["cwd"] = p.get("model"), p.get("effort"), p.get("cwd")
            elif p.get("type") == "token_count":
                if "info" not in s and p.get("info"):
                    s["info"] = p["info"]
                if "rate_limits" not in s and p.get("rate_limits"):
                    s["rate_limits"] = p["rate_limits"]
            if {"model", "info", "rate_limits"} <= s.keys():
                break
        sessions.append(s)
    sessions.sort(key=lambda s: s["_updated"], reverse=True)
    return sessions


def five_hour_used(agent, sessions):
    """% usado da janela de 5h (limite da conta), ou None se ainda não há dados."""
    if not sessions:
        return None
    limits = sessions[0].get("rate_limits") or {}
    if agent == "claude":
        return (limits.get("five_hour") or {}).get("used_percentage")
    return (limits.get("primary") or {}).get("used_percent")


def context_used(agent, sessions):
    """% de contexto da sessão mais recente; não soma contextos de sessões distintas."""
    if not sessions:
        return None
    session = sessions[0]
    if agent == "claude":
        return (session.get("context_window") or {}).get("used_percentage")
    info = session.get("info") or {}
    tokens = (info.get("last_token_usage") or {}).get("total_tokens")
    size = info.get("model_context_window")
    if tokens is not None and size and size > 0:
        return tokens / size * 100
    return None


def detail(text):
    return f"    <span color='{theme('dark_foreground', '#7a7a7a')}'>{text}</span>"


def claude_tooltip(state, sessions):
    lines = [f"<b><span color='{CLAUDE_ORANGE}'>Claude Code</span></b> · {state}"]
    if not sessions:
        return lines + [f"  <span color='{theme('dark_foreground', '#7a7a7a')}'>sem dados ainda (aparecem após a primeira resposta)</span>"]
    for d in sessions:
        model = d.get("model", {}).get("display_name", "?")
        effort = (d.get("effort") or {}).get("level")
        ctx = d.get("context_window") or {}
        used = ctx.get("used_percentage")
        info = f"  {model}{f' ({effort})' if effort else ''} · {html.escape(short_dir(d.get('cwd')))}"
        if used is not None:
            info += (f" · contexto {used:.0f}%"
                     f" ({fmt_tokens(ctx.get('total_input_tokens', 0))}/{fmt_tokens(ctx.get('context_window_size', 0))})")
        lines.append(info)
        cur = ctx.get("current_usage") or {}
        if cur:
            lines.append(detail(
                f"última resposta: entrada {fmt_tokens(cur.get('input_tokens', 0))}"
                f" · cache lido {fmt_tokens(cur.get('cache_read_input_tokens', 0))}"
                f" · cache gravado {fmt_tokens(cur.get('cache_creation_input_tokens', 0))}"
                f" · saída {fmt_tokens(cur.get('output_tokens', 0))}"))
        cache = d.get("prompt_cache") or {}
        if cache.get("hit_ratio") is not None:
            lines.append(detail(
                f"cache de prompt: {cache['hit_ratio'] * 100:.0f}% de acerto"
                f" · {cache.get('requests', 0)} requisições · {'quente' if cache.get('warm') else 'frio'}"))
    limits = sessions[0].get("rate_limits") or {}
    if "five_hour" in limits:
        lines.append(limit_line("5h", limits["five_hour"]["used_percentage"], limits["five_hour"]["resets_at"]))
    if "seven_day" in limits:
        lines.append(limit_line("Semana", limits["seven_day"]["used_percentage"], limits["seven_day"]["resets_at"]))
    return lines


def codex_tooltip(state, sessions):
    lines = [f"<b><span color='{agent_color('codex')}'>Codex</span></b> · {state}"]
    if not sessions:
        return lines + [f"  <span color='{theme('dark_foreground', '#7a7a7a')}'>sem dados ainda (aparecem após a primeira resposta)</span>"]
    for s in sessions:
        effort = s.get("effort")
        info = f"  {s.get('model') or '?'}{f' ({effort})' if effort else ''}"
        info += f" · {html.escape(short_dir(s.get('cwd')))}"
        tk = s.get("info") or {}
        last, size = (tk.get("last_token_usage") or {}).get("total_tokens"), tk.get("model_context_window")
        if last and size:
            info += f" · contexto {last / size * 100:.0f}% ({fmt_tokens(last)}/{fmt_tokens(size)})"
        lines.append(info)
        tot = tk.get("total_token_usage") or {}
        if tot.get("total_tokens"):
            lines.append(detail(
                f"sessão: {fmt_tokens(tot['total_tokens'])} tokens"
                f" · entrada {fmt_tokens(tot.get('input_tokens', 0))}"
                f" (cache {fmt_tokens(tot.get('cached_input_tokens', 0))})"
                f" · saída {fmt_tokens(tot.get('output_tokens', 0))}"
                f" · raciocínio {fmt_tokens(tot.get('reasoning_output_tokens', 0))}"))
    plan = (sessions[0].get("rate_limits") or {}).get("plan_type")
    if plan:
        lines.append(detail(f"plano: {plan}"))
    limits = sessions[0].get("rate_limits") or {}
    for key, label in (("primary", "5h"), ("secondary", "Semana")):
        w = limits.get(key)
        if w:
            if key == "primary" and w.get("window_minutes") != 300:
                label = f"{w['window_minutes'] // 60}h"
            lines.append(limit_line(label, w["used_percent"], w["resets_at"]))
    return lines


def render(found):
    if not found:
        return {"text": "", "class": "empty"}
    icons, per_agent = [], {}
    for ws, _x, _addr, title, agent, state, icon in found:
        color = theme("alert", "#fcee09") if state == "blocked" else agent_color(agent)
        icons.append(f"<span color='{color}'>{html.escape(icon)}</span>")
        label = {"idle": "parado", "working": "trabalhando", "blocked": "aguardando você"}[state]
        where = "em outra aba" if ws == "~" else f"[{ws}]"
        per_agent.setdefault(agent, []).append(f"{label} {where}")
    tips, metrics = [], []
    for agent, usage, tooltip in (("claude", claude_usage, claude_tooltip),
                                  ("codex", codex_usage, codex_tooltip)):
        if agent not in per_agent:
            continue
        sessions = usage()
        if tips:
            tips.append("")
        tips += tooltip(", ".join(per_agent[agent]), sessions)
        parts = []
        used = five_hour_used(agent, sessions)
        if used is not None:
            parts.append(f"5h <span color='{level_color(used)}'>{used:.0f}%</span>")
        context = context_used(agent, sessions)
        if context is not None:
            parts.append(f"ctx <span color='{level_color(context)}'>{context:.0f}%</span>")
        if parts:
            metrics.append(" · ".join(parts))
    states = {f[5] for f in found}
    css = "blocked" if "blocked" in states else "working" if "working" in states else "idle"
    # Preserva a disposição dos ícones: métricas antes do Codex, depois do Claude.
    icon_text, metric_text = "  ".join(icons), "  ".join(metrics)
    if not metric_text:
        text = icon_text
    elif set(per_agent) == {"codex"}:
        text = f"{metric_text} {icon_text}"
    else:
        text = f"{icon_text} {metric_text}"
    return {"text": text, "tooltip": "\n".join(tips), "class": css}


def render_modules(found):
    """Cada indicador visível desenha seu fundo; só há divisória se ambos existem."""
    outputs = {agent: render([f for f in found if f[4] == agent])
               for agent in ("codex", "claude")}
    if all(output["text"] for output in outputs.values()):
        for output in outputs.values():
            output["class"] = [output["class"], "paired"]
    return outputs


def focus_next(only=None):
    found = agents(only)
    if not found:
        return
    active = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True).stdout
    try:
        current = json.loads(active).get("address")
    except json.JSONDecodeError:
        current = None
    addrs = [f[2] for f in found if f[2]]  # sessões em abas de trás não têm janela própria
    if not addrs:
        return
    nxt = addrs[(addrs.index(current) + 1) % len(addrs)] if current in addrs else addrs[0]
    subprocess.run(["hyprctl", "dispatch", f'hl.dsp.focus({{ window = "address:{nxt}" }})'],
                   capture_output=True)


def hypr_events():
    path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                        os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock")
    sock = socket.socket(socket.AF_UNIX)
    sock.connect(path)
    return sock


def daemon():
    """Processo único: grava o estado de cada agente para os módulos lerem com tail -F."""
    os.makedirs(STATE_DIR, exist_ok=True)
    lock = open(os.path.join(STATE_DIR, "waybar.lock"), "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:  # já existe um rodando
        return
    sock = hypr_events()

    last = {}
    def emit():
        found = agents()
        for agent, output in render_modules(found).items():
            line = json.dumps(output, ensure_ascii=False)
            if line != last.get(agent):
                path = os.path.join(STATE_DIR, f"waybar-{agent}.json")
                with open(path + ".tmp", "w") as f:
                    f.write(line + "\n")
                os.replace(path + ".tmp", path)
                last[agent] = line

    wait_events(sock, emit)


def listen(only=None):
    sock = hypr_events()

    last = None
    def emit():
        nonlocal last
        line = json.dumps(render(agents(only)), ensure_ascii=False)
        if line != last:
            try:
                print(line, flush=True)
            except BrokenPipeError:  # o Waybar foi fechado
                sys.exit(0)
            last = line

    wait_events(sock, emit)


def wait_events(sock, emit):
    emit()
    sock.settimeout(REFRESH)
    buf = b""
    while True:
        try:
            data = sock.recv(4096)
        except socket.timeout:  # atualiza o uso de tokens mesmo sem eventos
            emit()
            continue
        if not data:
            break
        buf += data
        *lines, buf = buf.split(b"\n")
        if any(l.startswith((b"windowtitlev2>>", b"openwindow>>", b"closewindow>>", b"movewindowv2>>"))
               for l in lines):
            emit()


if __name__ == "__main__":
    args = sys.argv[1:]
    only = args.pop() if args and args[-1] in ("claude", "codex") else None
    if args and args[0] == "focus":
        focus_next(only)
    elif args and args[0] == "daemon":
        daemon()
    else:
        listen(only)
