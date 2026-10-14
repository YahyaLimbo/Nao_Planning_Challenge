#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
_pre_port="${NAO_PORT:-}"; _pre_home="${CHOREGRAPHE_HOME:-}"; _pre_run="${RUN_DIR:-}"
if [ -f .env ]; then
    set -a; . ./.env; set +a
fi
[ -n "$_pre_port" ] && NAO_PORT="$_pre_port"
[ -n "$_pre_home" ] && CHOREGRAPHE_HOME="$_pre_home"
[ -n "$_pre_run" ]  && RUN_DIR="$_pre_run"
true

: "${CHOREGRAPHE_HOME:?set CHOREGRAPHE_HOME to the extracted choregraphe-<ver>-ubuntu<rel> directory}"
PORT="${NAO_PORT:-9559}"
RUN_DIR="${RUN_DIR:-.run}"

BIN="${CHOREGRAPHE_HOME}/bin/naoqi-bin"
[ -x "$BIN" ] || { echo "!! no naoqi-bin at ${BIN}" >&2; exit 1; }

mkdir -p "$RUN_DIR"
echo "==> starting NAOqi on 0.0.0.0:${PORT} (log: ${RUN_DIR}/naoqi.log)"
LD_LIBRARY_PATH="${CHOREGRAPHE_HOME}/lib" "$BIN" \
    --qi-listen-url "tcp://0.0.0.0:${PORT}" \
    --disable-life \
    --pid-file "${RUN_DIR}/naoqi.pid" \
    > "${RUN_DIR}/naoqi.log" 2>&1 &

for _ in $(seq 1 60); do
    if grep -q 'Registered Service "ALRobotPosture"' "${RUN_DIR}/naoqi.log" 2>/dev/null; then
        echo "==> ALRobotPosture up. Services keep registering for ~20s more."
        echo "    stop it with: kill \$(cat ${RUN_DIR}/naoqi.pid)"
        echo "    then: NAO_IP=host.docker.internal NAO_PORT=${PORT} make smoke"
        exit 0
    fi
    sleep 1
done
echo "!! timed out; see ${RUN_DIR}/naoqi.log" >&2
exit 1
