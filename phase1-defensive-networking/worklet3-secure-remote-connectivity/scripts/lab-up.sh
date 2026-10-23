#!/usr/bin/env bash
# Bring the Zero Trust lab up or down.
# Usage: bash lab-up.sh up | down | status | rebuild
set -euo pipefail
cd "$(dirname "$0")"

# Support both the compose plugin (docker compose) and the old standalone binary.
if docker compose version >/dev/null 2>&1; then
    DC="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DC="docker-compose"
else
    echo "Docker Compose not found. Install Docker Engine and the compose plugin." >&2
    exit 1
fi

case "${1:-up}" in
    up)
        $DC up -d --build
        echo "Waiting for the server to generate keys and raise the tunnels..."
        sleep 6
        $DC ps
        echo "Try:  bash lab-up.sh status"
        ;;
    status)
        echo "=== server: entitlements and peers ==="
        docker exec zt-wg-server nft list table inet zerotrust 2>/dev/null || echo "(firewall not loaded yet)"
        docker exec zt-wg-server wg show 2>/dev/null || echo "(tunnel not up yet)"
        ;;
    rebuild)
        $DC build --no-cache
        ;;
    down)
        # Remove the keys volume too, so the next up starts from fresh keys.
        $DC down --volumes
        ;;
    *)
        echo "Usage: bash lab-up.sh up | down | status | rebuild" >&2
        exit 1
        ;;
esac
