#!/usr/bin/env bash
# One-command Zero Trust remote-access demo: least privilege, attack and
# detection, then live revocation and recovery. About five minutes.
# Usage: bash demo.sh [--auto] [--reset]
#   --auto   no pauses between scenes, for an unattended / recorded run
#   --reset  re-provision mallory and clear monitor state, back to the start
set -euo pipefail
cd "$(dirname "$0")"

AUTO=no
RESET=no
for a in "$@"; do
    [ "$a" = --auto ] && AUTO=yes
    [ "$a" = --reset ] && RESET=yes
done

if [ -t 1 ]; then
    B=$(tput bold); G=$(tput setaf 2); R=$(tput setaf 1); Y=$(tput setaf 3); N=$(tput sgr0)
else
    B=; G=; R=; Y=; N=
fi

scene() { echo; echo "${B}========== $* ==========${N}"; }
pause() { [ "$AUTO" = yes ] && return 0; read -rp "  ${Y}[enter] to continue${N}"; }

# expect_ok LABEL CONTAINER CMD...  -> PASS when the command succeeds with output
expect_ok() {
    local label="$1" cont="$2"; shift 2
    local out
    if out=$(docker exec "$cont" "$@" 2>/dev/null) && [ -n "$out" ]; then
        echo "  ${G}ALLOWED${N}  $label  -> ${out#"${out%%[![:space:]]*}"}"
    else
        echo "  ${R}FAILED${N}   $label  (expected this to work)"
    fi
}

# expect_blocked LABEL CONTAINER CMD...  -> correct when the command cannot connect
expect_blocked() {
    local label="$1" cont="$2"; shift 2
    if docker exec "$cont" "$@" >/dev/null 2>&1; then
        echo "  ${R}LEAK${N}     $label  (this should have been blocked!)"
    else
        echo "  ${G}BLOCKED${N}  $label  (correct, outside entitlement)"
    fi
}

monitor() { python3 wg-monitor.py --once --no-syslog "$@" | sed 's/^/  /' || true; }

CURL_WEB=(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://10.10.10.20)
CURL_WEB_FAIL=(curl -s -o /dev/null --max-time 5 http://10.10.10.20)
DB_PROBE=(timeout 7 nc -w 5 10.10.10.30 5432)

# --- preflight -------------------------------------------------------------
if ! docker ps --format '{{.Names}}' | grep -q zt-wg-server; then
    echo "Lab is not running, starting it..."
    bash lab-up.sh up
fi
echo "Waiting for tunnels..."
for _ in $(seq 1 30); do
    docker exec zt-client-alice wg show wg0 >/dev/null 2>&1 && break
    sleep 1
done

if [ "$RESET" = yes ]; then
    bash provision-peer.sh mallory --skip-posture >/dev/null 2>&1 || true
fi
rm -f .wg-monitor-state.json
monitor >/dev/null   # baseline, so later drop counts are deltas from this run

cat <<INTRO

${B}Zero Trust remote access${N}
Three identities on one tunnel, each allowed only what its role needs:
  alice   developer   -> web app only        (10.10.10.20:80)
  bob     dba         -> database only        (10.10.10.30:5432)
  mallory contractor  -> web app  (compromised laptop, used later)
INTRO
pause

# --- scene 1 ---------------------------------------------------------------
scene "Scene 1  Least privilege, access is scoped to identity"
expect_ok      "alice -> web " zt-client-alice "${CURL_WEB[@]}"
expect_blocked "alice -> db  " zt-client-alice "${DB_PROBE[@]}"
expect_ok      "bob   -> db  " zt-client-bob   "${DB_PROBE[@]}"
expect_blocked "bob   -> web " zt-client-bob   "${CURL_WEB_FAIL[@]}"
echo "  Same tunnel, different reach. A stolen key is worth only one service."
pause

# --- scene 2 ---------------------------------------------------------------
scene "Scene 2  Attack and detection"
echo "  Port-scanning the VPN endpoint from an attacker on the edge network:"
docker exec zt-client-bob nmap -sU -p 51820 --host-timeout 10s 172.28.0.10 \
    | sed -n '/PORT/,/^$/p' | sed 's/^/    /' || true
echo "  WireGuard does not answer unauthenticated packets, so it does not advertise itself."
echo
echo "  mallory's laptop is compromised. The attacker widens its tunnel routes to"
echo "  probe past her entitlement (web) toward the database:"
SRV=$(docker exec zt-client-mallory wg show wg0 peers | head -n1)
docker exec zt-client-mallory wg set wg0 peer "$SRV" allowed-ips 10.10.10.0/24,10.20.0.0/24
docker exec zt-client-mallory ip route replace 10.10.10.0/24 dev wg0 2>/dev/null || true
expect_blocked "mallory -> db" zt-client-mallory "${DB_PROBE[@]}"
echo "  The client was widened, but the gateway still enforces least privilege,"
echo "  the two layers are independent. The monitor sees the dropped traffic:"
monitor
pause

# --- scene 3 ---------------------------------------------------------------
scene "Scene 3  Respond and recover, live"
echo "  Operator revokes mallory:"
bash revoke-peer.sh mallory | sed 's/^/    /'
echo
expect_blocked "mallory -> web" zt-client-mallory "${CURL_WEB_FAIL[@]}"
expect_ok      "alice   -> web" zt-client-alice   "${CURL_WEB[@]}"
echo "  mallory is off the network within one keepalive interval; alice never noticed."
echo "  Peers still on the gateway:"
docker exec zt-wg-server wg show wg0 peers | sed 's/^/    /' || true

echo
echo "${B}Done.${N} Re-run from the top with:  bash demo.sh --reset"
