/* Waybar do Tron Arcade (gerada pelo theme-set; substitui o waybar.css.tpl padrão).
   Um HUD de fliperama: faixa inteira com linha neon embaixo, cantos retos, workspaces como
   blocos de seleção de fase (o atual aceso) e módulos separados como num placar */
@import url("colors.css");

* {
    font-family: "{{ font }}", "Noto Sans", monospace;
    font-size: {{ font_size }}px;
    min-height: 0;
    border: none;
    border-radius: 0;
}

window#waybar {
    background-color: alpha(@background, 0.94);
    color: @foreground;
    border-bottom: 2px solid @accent;
}

tooltip {
    background: @background;
    border: 2px solid @accent;
}
tooltip label { color: @foreground; }

button {
    box-shadow: none;
    border-radius: 0;
}
button:hover {
    background: alpha(@accent, 0.15);
    box-shadow: none;
}

/* Workspaces: blocos com moldura; o atual aceso em ciano, urgente em rosa */
#workspaces { margin: 0 4px; }
#workspaces button {
    padding: 0 6px;
    margin: 5px 2px;
    color: @foreground;
    background: transparent;
    border: 2px solid alpha(@accent, 0.5);
}
#workspaces button.empty { color: @muted; border-color: @muted; }
#workspaces button.active { color: @background; background: @accent; border-color: @accent; }
#workspaces button.urgent { color: @background; background: @alert; border-color: @alert; }
#workspaces button:hover { background: alpha(@accent, 0.2); }

/* Módulos separados por traços verticais, como os campos de um placar */
#clock, #custom-notification, #custom-screenshot, #tray, #pulseaudio, #backlight, #network,
#bluetooth, #cpu, #memory, #power-profiles-daemon, #battery, #custom-power {
    padding: 0 10px;
    color: @foreground;
    border-left: 2px solid @muted;
}
#clock { color: @highlight; border-right: 2px solid @muted; }
#custom-power { color: @alert; }

#battery.charging, #battery.plugged { color: @good; }
#battery.warning, #network.disconnected, #pulseaudio.muted { color: @alert; }
#battery.critical:not(.charging) {
    color: @background;
    background: @alert;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(2);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}
@keyframes blink {
    to { background-color: @background; color: @alert; }
}

/* Sino com notificações guardadas */
#custom-notification.notification, #custom-notification.dnd-notification { color: @alert; }

#custom-codex, #custom-claude { padding: 0 10px; }
#custom-codex.working, #custom-claude.working { box-shadow: inset 0 -3px @accent; }
#custom-codex.blocked, #custom-claude.blocked { box-shadow: inset 0 -3px @alert; }

#power-profiles-daemon.performance { color: @alert; }
#power-profiles-daemon.balanced { color: @accent; }
#power-profiles-daemon.power-saver { color: @good; }
