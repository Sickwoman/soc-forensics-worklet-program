#!/usr/bin/env bash
# Lightweight Worklet 4 lab: the Wazuh manager only, in Docker, demonstrated with
# wazuh-logtest. No indexer or dashboard, so it fits an 8 GB host (the manager
# uses ~350 MiB). The dashboard is the "more RAM" extension, see the README.
#
# Usage: bash wazuh-lab.sh up | rules | test | down
#   up     start the manager container and wait for it to initialise
#   rules  load the custom decoder and the Zero Trust bridge rules, then restart
#   test   prove detection: SSH brute force, and the Worklet 3 -> 4 bridge alerts
#   down   remove the container
set -euo pipefail
cd "$(dirname "$0")"
IMG=wazuh/wazuh-manager:4.9.2
C=wazuh-manager

wait_up() {
    echo "waiting for the manager to initialise (a cold start can take 1-2 minutes)..."
    for _ in $(seq 1 36); do
        if docker exec "$C" /var/ossec/bin/wazuh-control status 2>/dev/null | grep -q "wazuh-analysisd is running"; then
            echo "manager is up"; return 0
        fi
        sleep 5
    done
    # Not fatal: on a low-RAM host it may still be warming up, and the rules step
    # restarts it anyway. Continue rather than alarm the user.
    echo "manager is slow to report ready; continuing (the 'rules' step will restart it)"
    return 0
}

case "${1:-}" in
    up)
        if docker ps -a --format '{{.Names}}' | grep -qx "$C"; then
            docker start "$C" >/dev/null
        else
            docker run -d --name "$C" "$IMG" >/dev/null
        fi
        wait_up
        docker exec "$C" /var/ossec/bin/wazuh-control info 2>/dev/null | head -2 || true
        docker stats --no-stream --format 'memory: {{.MemUsage}}' "$C" 2>/dev/null || true
        ;;
    rules)
        docker cp ../config/wazuh-decoder-example.xml "$C":/var/ossec/etc/decoders/local_decoder.xml
        docker cp ../config/wazuh-local-rules.xml     "$C":/var/ossec/etc/rules/local_rules.xml
        docker exec "$C" chown wazuh:wazuh /var/ossec/etc/decoders/local_decoder.xml /var/ossec/etc/rules/local_rules.xml 2>/dev/null || true
        docker exec "$C" /var/ossec/bin/wazuh-control restart >/dev/null
        sleep 15
        echo "custom decoder and Zero Trust bridge rules loaded"
        ;;
    test)
        echo "== SSH brute force (10 failed logins, one source IP) =="
        for n in $(seq 1 10); do
            printf 'Oct 23 10:00:%02d host sshd[%d]: Failed password for invalid user admin from 10.20.0.9 port 51000 ssh2\n' "$n" $((2000 + n))
        done | docker exec -i "$C" /var/ossec/bin/wazuh-logtest 2>&1 | grep -E "id: '5712'|brute force" | head -2

        echo "== Zero Trust bridge: denied_traffic (Worklet 3 wg-monitor) =="
        echo '{"type":"denied_traffic","severity":"high","source":"wg-monitor"}' \
            | docker exec -i "$C" /var/ossec/bin/wazuh-logtest 2>&1 | grep -E "id: '1001|Zero Trust" | head -2

        echo "== Zero Trust bridge: unknown_peer =="
        echo '{"type":"unknown_peer","severity":"high","source":"wg-monitor"}' \
            | docker exec -i "$C" /var/ossec/bin/wazuh-logtest 2>&1 | grep -E "id: '1001|Zero Trust" | head -2
        ;;
    down)
        docker rm -f "$C" >/dev/null 2>&1 || true
        echo "manager removed"
        ;;
    *)
        echo "Usage: bash wazuh-lab.sh up | rules | test | down" >&2
        exit 1
        ;;
esac
