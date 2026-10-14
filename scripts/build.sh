#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ] || ! grep -q '^DOCKER_UID=' .env 2>/dev/null; then
    printf 'DOCKER_UID=%s\nDOCKER_GID=%s\n' "$(id -u)" "$(id -g)" >> .env
    echo "==> wrote DOCKER_UID/DOCKER_GID to .env"
fi

shopt -s nullglob
pynaoqi=(vendor/*pynaoqi*linux*.tar.gz)
sdk=(vendor/*naoqi-sdk*linux*.tar.gz)
shopt -u nullglob

if [ ${#pynaoqi[@]} -eq 0 ]; then
    echo "!! No pynaoqi tarball in ./vendor - read vendor/README.md first." >&2
    echo "   Building the planner image only." >&2
    docker compose build planner
    exit 1
fi

echo "==> pynaoqi: ${pynaoqi[0]}"
if [ ${#sdk[@]} -eq 0 ]; then
    echo "==> naoqi-sdk: (none) - no containerised virtual robot, see README Option B"
else
    echo "==> naoqi-sdk: ${sdk[0]}"
fi

docker compose build
echo
echo "Done. Next: scripts/fetch_positions.sh"
