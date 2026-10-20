#!/bin/sh
# Sai com 0 (verdadeiro) se o notebook está na bateria, 1 se está na tomada.
for s in /sys/class/power_supply/*; do
    [ "$(cat "$s/type" 2>/dev/null)" = "Mains" ] && [ "$(cat "$s/online" 2>/dev/null)" = "1" ] && exit 1
done
exit 0
