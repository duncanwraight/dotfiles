#!/bin/bash

# To use this script, follow these instructions:
# 1- Move the script to a directory like /usr/local/bin
# 2- Find your DISPLAY value by running `w | tail -n 1 | awk '{print $2}'`
# 3- Find your user ID by running `id -u`
# 4- Run `chmod +x` on the script
# 5- Run `crontab -e` and add the following line to the bottom, replacing the DISPLAY, user ID and directory values as required
# * * * * * export DISPLAY=:0 && export XDG_RUNTIME_DIR="/run/user/1000" && /usr/local/bin/low_battery_warning.sh >> /var/log/battery_warning.log 2>&1
# 6- Run `sudo touch /var/log/battery_warning.log && sudo chown user:user /var/log/battery_warning.log` to create the log file
# 6b I would recommend creating a logrotate config file to deal with this log as it will get quite big over a few months

POWER_SUPPLY_PATH="/sys/class/power_supply/BAT0/"
STATUS=`cat $POWER_SUPPLY_PATH/status`
CAPACITY=`cat $POWER_SUPPLY_PATH/capacity`

if test -f "$POWER_SUPPLY_PATH/charge_now"; then
    FULL_CHARGE_WATTAGE=`cat $POWER_SUPPLY_PATH/charge_full`
    CURRENT_CHARGE_WATTAGE=`cat $POWER_SUPPLY_PATH/charge_now`
elif test -f "$POWER_SUPPLY_PATH/energy_now"; then
    FULL_CHARGE_WATTAGE=`cat $POWER_SUPPLY_PATH/energy_full`
    CURRENT_CHARGE_WATTAGE=`cat $POWER_SUPPLY_PATH/energy_now`
else
    echo "FATAL ERROR: Unable to locate power supply charge information. Exiting..."
    exit 1
fi

# Bash can't handle floating point multiplication; use AWK instead
BATTERY_PERCENTAGE_TO_ALARM_AT=15
ALARM_LEVEL=$(awk -v capacity="${FULL_CHARGE_WATTAGE}" -v multiplier=0.${BATTERY_PERCENTAGE_TO_ALARM_AT} 'BEGIN{alarm=(capacity*multiplier); print alarm}')

echo -n '['
echo -n "`date '+%d/%m/%Y %H:%M:%S'`"
echo -n "  Status: $STATUS"
echo -n " // Capacity: $CAPACITY"
echo -n " // Full charge wattage: $FULL_CHARGE_WATTAGE"
echo -n " // Current charge wattage: $CURRENT_CHARGE_WATTAGE"
echo -n " // Alarm level wattage: $ALARM_LEVEL"
echo -n " // \$DISPLAY: $DISPLAY"
echo -n " // \$XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo -n ']'
echo

MESSAGE='<span>Your battery level is low.</span>'
MESSAGE+='<span size="x-large" weight="ultrabold" foreground="orange">\n\n'
MESSAGE+=$CAPACITY
MESSAGE+='%\n</span>'

if [[ "$STATUS" == "Discharging" ]] && [ "$CURRENT_CHARGE_WATTAGE" -le "$ALARM_LEVEL" ] ; then
    if pgrep yad > /dev/null 2>&1 ; then
        pkill -f "yad" 
    fi
    echo "Battery is discharging and current charge is less than alarm level"
    paplay /usr/share/sounds/sound-icons/prompt &
    yad --title="Low battery" --on-top --splash --width=800 --text="$MESSAGE" --text-align=center --image=dialog-warning --borders=40 --center --undecorated --button=' Acknowledge!gtk-ok:0'
fi
