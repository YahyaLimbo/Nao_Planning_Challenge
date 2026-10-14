#!/bin/bash
set -euo pipefail

PORT="${NAOQI_PORT:-9559}"

if [ ! -x "${NAOQI_SDK_HOME}/naoqi" ] && [ ! -x "${NAOQI_SDK_HOME}/bin/naoqi-bin" ]; then
    cat >&2 <<'MSG'
ERROR: no NAOqi broker in this image.
       The naoqi-sdk-<version>-linux64 tarball was not in ./vendor at build time.
       Either add it and rebuild (scripts/build.sh), or run Choregraphe's
       virtual robot on the host and point NAO_IP/NAO_PORT at it
       (see README.md, "Option B").
MSG
    exit 1
fi

NAOQI_BIN="${NAOQI_SDK_HOME}/naoqi"
[ -x "$NAOQI_BIN" ] || NAOQI_BIN="${NAOQI_SDK_HOME}/bin/naoqi-bin"
if "$NAOQI_BIN" --help 2>&1 | grep -q -- "--qi-listen-url"; then
    DEFAULT_ARGS="--qi-listen-url tcp://0.0.0.0:${PORT} --disable-life"
else
    DEFAULT_ARGS="--verbose --broker-ip 0.0.0.0 --broker-port ${PORT}"
fi
ARGS="${NAOQI_ARGS:-$DEFAULT_ARGS}"

echo "==> ${NAOQI_BIN} ${ARGS}"
exec "$NAOQI_BIN" $ARGS
