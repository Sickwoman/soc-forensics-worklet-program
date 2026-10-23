#!/usr/bin/env bash
# OPTIONAL: the full Wazuh with the web dashboard (manager + indexer + dashboard),
# the official single-node deployment. It needs roughly 4 to 6 GB of RAM, so it
# does NOT fit the 8 GB manager-only lab in wazuh-lab.sh. Run this only on a host,
# or a WSL with a raised memory cap, that can spare the RAM; see
# docs/dashboard-setup.md. On an 8 GB machine running Windows too, expect it to be
# slow or to fail to start the indexer.
#
# Usage: bash wazuh-dashboard.sh up | down | info
set -euo pipefail
DIR=${WAZUH_DOCKER_DIR:-$HOME/wazuh-docker}
TAG=v4.9.2

case "${1:-}" in
    up)
        # The indexer (OpenSearch) refuses to start without this.
        sysctl -w vm.max_map_count=262144 >/dev/null 2>&1 || \
            echo "WARN: could not set vm.max_map_count; the indexer may not start" >&2
        [ -d "$DIR/.git" ] || git clone -q --branch "$TAG" https://github.com/wazuh/wazuh-docker.git "$DIR"
        cd "$DIR/single-node"
        echo "generating certificates..."
        docker compose -f generate-indexer-certs.yml run --rm generator
        echo "starting the stack (the indexer can take several minutes to be ready)..."
        docker compose up -d
        echo "When ready, open https://localhost and sign in as admin."
        echo "Change the default admin password in docker-compose.yml before any real use."
        ;;
    down)
        cd "$DIR/single-node" && docker compose down
        ;;
    info)
        echo "The dashboard stack needs ~4-6 GB. On WSL, raise the cap first:"
        echo "  create C:\\Users\\<you>\\.wslconfig with:"
        echo "    [wsl2]"
        echo "    memory=6GB"
        echo "  then run 'wsl --shutdown' in PowerShell and start the distro again."
        echo "See docs/dashboard-setup.md."
        ;;
    *)
        echo "Usage: bash wazuh-dashboard.sh up | down | info" >&2
        exit 1
        ;;
esac
