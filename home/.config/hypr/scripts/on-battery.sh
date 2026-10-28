#!/bin/sh
# Só considera bateria quando existe uma bateria descarregando.
# Um desktop sem bateria não deve apagar a tela ou suspender por esta regra.
for s in /sys/class/power_supply/*; do
    [ "$(cat "$s/type" 2>/dev/null)" = "Battery" ] || continue
    [ "$(cat "$s/status" 2>/dev/null)" = "Discharging" ] && exit 0
done
exit 1
