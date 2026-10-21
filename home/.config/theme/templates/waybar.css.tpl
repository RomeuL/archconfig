/* Waybar no tema {{ theme_title }} (gerado pelo theme-set a partir de
   ~/.config/theme/templates/waybar.css.tpl; um tema pode trazer o seu próprio waybar.css.tpl).
   Estilo Cyber-Arch, portado de github.com/V1xEr3bus/Cyber-Arch: barra transparente com três
   "ilhas". Cores: foreground (texto), accent, active (ativo), highlight (hover), alert, good, muted */
@import url("colors.css");

* {
    font-family: "{{ font }}", "Noto Sans CJK JP", "Noto Sans", sans-serif;
    font-size: {{ font_size }}px;
    min-height: 0;
    border: none;
    border-radius: 0;
}

window#waybar {
    background-color: transparent;
    color: @foreground;
}

.modules-left,
.modules-center,
.modules-right {
    background-color: alpha(@background, 0.75);
    border-radius: {{ rounding }}px;
    padding: 0 6px;
}

tooltip {
    background: alpha(@background, 0.92);
    border: 1px solid @accent;
    border-radius: {{ rounding_small }}px;
}
tooltip label { color: @foreground; }

button {
    box-shadow: inset 0 -3px transparent;
    border-radius: 0;
}
button:hover {
    background: inherit;
    box-shadow: inset 0 -3px @highlight;
}

#workspaces button {
    padding: 0 7px;
    color: @foreground;
    background: transparent;
}
#workspaces button.empty { color: @muted; }
#workspaces button.active { color: @active; }
#workspaces button.urgent { color: @alert; }

#clock, #custom-notification, #custom-screenshot, #tray, #pulseaudio, #backlight, #network,
#bluetooth, #cpu, #memory, #power-profiles-daemon, #battery, #custom-power {
    padding: 0 9px;
    color: @foreground;
    background-color: transparent;
}

#battery.charging, #battery.plugged { color: @active; }
#battery.warning, #network.disconnected, #pulseaudio.muted { color: @alert; }
#battery.critical:not(.charging) {
    color: @alert;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
}
@keyframes blink {
    to { background-color: #ffffff; color: #000000; }
}

/* Sino com notificações guardadas */
#custom-notification.notification, #custom-notification.dnd-notification { color: @alert; }

#custom-codex, #custom-claude { padding: 0 10px; font-size: {{ font_size }}px; }
#custom-codex.working, #custom-claude.working { box-shadow: inset 0 -3px @active; }
#custom-codex.blocked, #custom-claude.blocked { box-shadow: inset 0 -3px @alert; }

#power-profiles-daemon.performance { color: @alert; }
#power-profiles-daemon.balanced { color: @active; }
#power-profiles-daemon.power-saver { color: @good; }
