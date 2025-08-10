set -xeuo pipefail

EXEC_NAME=flatpak-cheat.sh
PROJECT_DIR=flatpak-cheat
UNPACK_PATH=/home/deck/"${PROJECT_DIR}"
PROJECT_NAME="flatpak openh264 fix"

HTTP_PATH="http://ciscobinary.openh264.org/libopenh264-"
OPENH264_VERSION="2.4.1-linux64.7.so.bz2
2.2.0-linux64.6.so.bz2
2.1.1-linux64.6.so.bz2
2.5.0-linux64.7.so.bz2
2.3.0-linux64.6.so.bz2
2.3.1-linux64.7.so.bz2
2.5.1-linux64.7.so.bz2"

if [ "$@" = "-d" ]; then
    cd "${PROJECT_DIR}"
    rm -f lib*
    while read -r link; do
        wget "$HTTP_PATH""$link"
    done <<< "$OPENH264_VERSION"
    cd -
fi
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
                  ./"${EXEC_NAME}" \
                  "$PROJECT_NAME" \
                  "${UNPACK_PATH}"/"${EXEC_NAME}"