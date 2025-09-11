#!/bin/bash

choice=$(echo -e "Enable\nDisable\nScan\nDevices\nManager" | ~/.local/bin/dmenu -p "Bluetooth:" -l 8)

case "$choice" in
    "Enable")
        bluetoothctl power on
        ;;
    "Disable")
        bluetoothctl power off
        ;;
    "Scan")
        bluetoothctl scan on &
        ;;
    "Devices")
        ~/.local/bin/dmenu -p "Devices:" -l 15 < <(bluetoothctl devices | head -15)
        ;;
    "Manager")
        blueman-manager &
        ;;
esac
