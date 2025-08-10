#!/bin/bash
set -eu
SERVER_DIR="/home/deck/flatpak-cheat"
DOMAIN="ciscobinary.openh264.org"
HOSTS_ENTRY="127.0.0.1 $DOMAIN"

. /etc/os-release
if [ "$ID" != "steamos" ]; then
    echo "This script for SteamOS only! Exiting..." >&2
    exit 1
fi

mkdir -p "$SERVER_DIR"

cd "$SERVER_DIR"
python3 -m http.server 80 1>/dev/null &
PID=$!

sleep 2

tee -a /etc/hosts >/dev/null <<EOF
$HOSTS_ENTRY
EOF

cleanup () {
    echo "Cleanup..."
        kill "$PID"
        sed -i "/$HOSTS_ENTRY/d" /etc/hosts
        rm -rf "$SERVER_DIR"
        echo "Cleanup done."
}

trap cleanup EXIT ERR

su - deck -c "flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
for ver in "2.4.1" "2.2.0" "19.08" "2.0" "2.5.0" "2.5.1" "2.3.0" "2.3.1"; do
        su - deck -c "flatpak install -u --runtime --noninteractive runtime/org.freedesktop.Platform.openh264/x86_64/$ver"
done

echo "Runtimes added. Done."