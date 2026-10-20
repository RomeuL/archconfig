#!/bin/sh
# Escurece a tela (só na bateria) e lembra que escureceu, para restaurar depois.
FLAG="$XDG_RUNTIME_DIR/hypridle-dimmed"
case "$1" in
    on)  ~/.config/hypr/scripts/on-battery.sh && brightnessctl -s set 10 && touch "$FLAG" ;;
    off) [ -f "$FLAG" ] && brightnessctl -r && rm -f "$FLAG" ;;
esac
exit 0
