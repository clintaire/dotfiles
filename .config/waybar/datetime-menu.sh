#!/bin/bash

choice=$(echo -e 'Set Date/Time\nChange Timezone\nWorld Clock\nSet Timer\nKOrganizer' | rofi -dmenu -theme ~/.config/rofi/launchers/type-4/style-1.rasi -p 'DateTime')

case "$choice" in
    'Set Date/Time')
        kitty -e sudo bash -c 'echo "Current: $(date)"; read -p "Enter new date/time (YYYY-MM-DD HH:MM:SS): " dt; timedatectl set-time "$dt"'
        ;;
    'Change Timezone')
        tz=$(timedatectl list-timezones | rofi -dmenu -theme ~/.config/rofi/launchers/type-4/style-1.rasi -p 'Select Timezone' -lines 15)
        [ -n "$tz" ] && kitty -e sudo timedatectl set-timezone "$tz"
        ;;
    'World Clock')
        echo -e "Anchorage: $(TZ=America/Anchorage date +'%H:%M %Z')\nLos Angeles: $(TZ=America/Los_Angeles date +'%H:%M %Z')\nDenver: $(TZ=America/Denver date +'%H:%M %Z')\nChicago: $(TZ=America/Chicago date +'%H:%M %Z')\nNew York: $(TZ=America/New_York date +'%H:%M %Z')\nHalifax: $(TZ=America/Halifax date +'%H:%M %Z')\nCaracas: $(TZ=America/Caracas date +'%H:%M %Z')\nSao Paulo: $(TZ=America/Sao_Paulo date +'%H:%M %Z')\nBuenos Aires: $(TZ=America/Argentina/Buenos_Aires date +'%H:%M %Z')\nReykjavik: $(TZ=Atlantic/Reykjavik date +'%H:%M %Z')\nLondon: $(TZ=Europe/London date +'%H:%M %Z')\nParis: $(TZ=Europe/Paris date +'%H:%M %Z')\nBerlin: $(TZ=Europe/Berlin date +'%H:%M %Z')\nRome: $(TZ=Europe/Rome date +'%H:%M %Z')\nWarsaw: $(TZ=Europe/Warsaw date +'%H:%M %Z')\nHelsinki: $(TZ=Europe/Helsinki date +'%H:%M %Z')\nAthens: $(TZ=Europe/Athens date +'%H:%M %Z')\nIstanbul: $(TZ=Europe/Istanbul date +'%H:%M %Z')\nMoscow: $(TZ=Europe/Moscow date +'%H:%M %Z')\nCasablanca: $(TZ=Africa/Casablanca date +'%H:%M %Z')\nLagos: $(TZ=Africa/Lagos date +'%H:%M %Z')\nCairo: $(TZ=Africa/Cairo date +'%H:%M %Z')\nNairobi: $(TZ=Africa/Nairobi date +'%H:%M %Z')\nJohannesburg: $(TZ=Africa/Johannesburg date +'%H:%M %Z')\nTehran: $(TZ=Asia/Tehran date +'%H:%M %Z')\nDubai: $(TZ=Asia/Dubai date +'%H:%M %Z')\nKarachi: $(TZ=Asia/Karachi date +'%H:%M %Z')\nMumbai: $(TZ=Asia/Kolkata date +'%H:%M %Z')\nDhaka: $(TZ=Asia/Dhaka date +'%H:%M %Z')\nBangkok: $(TZ=Asia/Bangkok date +'%H:%M %Z')\nSingapore: $(TZ=Asia/Singapore date +'%H:%M %Z')\nJakarta: $(TZ=Asia/Jakarta date +'%H:%M %Z')\nBeijing: $(TZ=Asia/Shanghai date +'%H:%M %Z')\nHong Kong: $(TZ=Asia/Hong_Kong date +'%H:%M %Z')\nTokyo: $(TZ=Asia/Tokyo date +'%H:%M %Z')\nSeoul: $(TZ=Asia/Seoul date +'%H:%M %Z')\nPerth: $(TZ=Australia/Perth date +'%H:%M %Z')\nSydney: $(TZ=Australia/Sydney date +'%H:%M %Z')\nAuckland: $(TZ=Pacific/Auckland date +'%H:%M %Z')\nFiji: $(TZ=Pacific/Fiji date +'%H:%M %Z')\nHonolulu: $(TZ=Pacific/Honolulu date +'%H:%M %Z')\nUTC: $(TZ=UTC date +'%H:%M %Z')" | rofi -dmenu -theme ~/.config/rofi/launchers/type-4/style-1.rasi -p 'World Clock' -lines 25
        ;;
    'Set Timer')
        min=$(rofi -dmenu -theme ~/.config/rofi/launchers/type-4/style-1.rasi -p 'Timer (minutes - numbers only)')
        if [ -n "$min" ] && [ "$min" -eq "$min" ] 2>/dev/null; then
            (sleep $((min*60)) && notify-send "Timer Done" "$min minutes elapsed" --urgency=critical) &
            notify-send "Timer Started" "$min minute timer started"
        fi
        ;;
    'KOrganizer')
        korganizer &
        ;;
esac