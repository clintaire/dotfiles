#!/bin/bash

choice=$(echo -e "Network Info\nWiFi List\nVPN Status\nSettings" | ~/.local/bin/dmenu -p "Network:" -l 8)

case "$choice" in
    "Network Info")
        ~/.local/bin/dmenu -p "Network Info:" -l 20 < <(ip addr show | head -20)
        ;;
    "WiFi List")
        ~/.local/bin/dmenu -p "WiFi Networks:" -l 15 < <(nmcli device wifi list | head -15)
        ;;
    "VPN Status")
        vpn_choice=$(echo -e "Show VPN Status\nAdd VPN\nBack" | ~/.local/bin/dmenu -p "VPN Menu:" -l 5)
        case "$vpn_choice" in
            "Show VPN Status")
                ~/.local/bin/dmenu -p "VPN Status:" -l 10 < <(ip route | grep tun0 || echo "No VPN active")
                ;;
            "Add VPN")
                nm-connection-editor &
                ;;
            "Back")
                # do nothing, return to main menu or exit
                ;;
        esac
        ;;
    "Settings")
        nm-connection-editor &
        ;;
esac

