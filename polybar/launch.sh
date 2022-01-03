#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar1 and bar2
echo "---" | tee -a /tmp/polybar-top.log /tmp/polybar-bottom.log
polybar top >>/tmp/polybar-top.log 2>&1 &
polybar bottom >>/tmp/polybar-bottom.log 2>&1 &
polybar external1 >>/tmp/polybar-ext1.log 2>&1 &
polybar external2 >>/tmp/polybar-ext2.log 2>&1 &

echo "Bars launched..."

##!/usr/bin/env bash
#
## Terminate any currently running instances
#killall -q polybar
#
## Pause while killall completes
#while pgrep -u $UID -x polybar > /dev/null; do sleep 1; done
#
#if type "xrandr" > /dev/null; then
#  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
#    MONITOR=$m polybar --reload top -c ~/.config/polybar/config &
#  done
#else
#  polybar --reload top -c ~/.config/polybar/config &
#fi
#
## Launch bar(s)
## polybar dummy -q &
## polybar top -q &
## polybar bottom -q  &
