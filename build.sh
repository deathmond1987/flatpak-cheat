#!/usr/bin/env bash

set -xeuo pipefail

##project opts
EXEC_NAME=flatpak-cheat.sh
PROJECT_DIR=flatpak-cheat
UNPACK_PATH=/home/deck/"${PROJECT_DIR}"
OUTPUT_DIR=out
PROJECT_DESCRIPTION="flatpak openh264 fix v"
OPENH264_VERSIONS="19.08 2.0 2.2.0 2.3.0 2.3.1 2.4.1 2.5.0 2.5.1"
##lib path
HTTP_PATH="http://ciscobinary.openh264.org/libopenh264-"

## TODO:
## get download list
## DOWNLOAD_URL=$(curl -s https://github.com/cisco/openh264/releases | grep linux64 | grep so.bz2 | cut -d " " -f2 | cut -d= -f 2 | tr -d "\"")
## INSTALL_VERSIONS=$(echo $DOWNLOAD_URL | cut -d - -f2)
## ADD VERSIONS TO: for ver in "2.4.1" "2.2.0" "19.08" "2.0" "2.5.0" "2.5.1" "2.3.0" "2.3.1"; do
##                      su - deck -c "flatpak install -u --runtime --noninteractive runtime/org.freedesktop.Platform.openh264/x86_64/$ver"
##                  done

##lib path
HTTP_PATH="http://ciscobinary.openh264.org/libopenh264-"
OPENH264_VERSION="2.0.0-linux64.5.so.bz2
2.1.1-linux64.6.so.bz2
2.2.0-linux64.6.so.bz2
2.3.0-linux64.6.so.bz2
2.3.1-linux64.7.so.bz2
2.4.1-linux64.7.so.bz2
2.5.0-linux64.7.so.bz2
2.5.1-linux64.7.so.bz2"

## assign version
PROJECT_VERSION=$(echo "$OPENH264_VERSION" | sort -V| tail -1 | cut -d- -f1)


## main
echo "Building flatpak fix version $PROJECT_VERSION"

## init dirs and files
if [ -d $PROJECT_DIR ]; then
    rm -rf $PROJECT_DIR $OUTPUT_DIR
fi
mkdir -p "${PROJECT_DIR}" "$OUTPUT_DIR"

cat <<'EOT' > $PROJECT_DIR/$EXEC_NAME
#!/usr/bin/env bash
set -euo pipefail

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
EOT

cat << EOF >> $PROJECT_DIR/$EXEC_NAME
for ver in $OPENH264_VERSIONS; do
    su - deck -c "flatpak install -u --runtime --noninteractive runtime/org.freedesktop.Platform.openh264/x86_64/\$ver"
done

echo "Runtimes added. Done."
EOF

cd "${PROJECT_DIR}"
while read -r link; do
    wget "$HTTP_PATH""$link"
done <<< "$OPENH264_VERSION"
cd -

chmod 777 ./"${PROJECT_DIR}"/"${EXEC_NAME}"
chown -R 1000:1000 ./*

makeself --xz \
         --complevel 9 \
         --notemp \
         --nox11 \
         --nocrc \
         --needroot \
         --target "${UNPACK_PATH}" \
                  ./"${PROJECT_DIR}" \
                  ./out/${EXEC_NAME//.sh/"-${PROJECT_VERSION}".sh} \
                  "$PROJECT_DESCRIPTION""$PROJECT_VERSION" \
                  "${UNPACK_PATH}"/"${EXEC_NAME}"
