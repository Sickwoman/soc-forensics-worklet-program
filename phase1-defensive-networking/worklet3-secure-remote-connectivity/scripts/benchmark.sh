#!/usr/bin/env bash
# Measure the WireGuard tunnel: throughput, latency, handshake time, and the
# container footprint. Numbers make the protocol comparison evidence instead of
# opinion. Fills the table in docs/benchmark-results.md.
# Usage: bash benchmark.sh
set -euo pipefail
cd "$(dirname "$0")"
GW=zt-wg-server
CLIENT=zt-client-alice
TUNNEL_SERVER_IP=10.20.0.1

echo "== WireGuard tunnel benchmark =="
date -u +"run: %Y-%m-%dT%H:%M:%SZ"

# The client only routes its entitled service by default, so add the gateway's
# tunnel address to its allowed-ips for the measurement (this measures the raw
# encrypted path to the server; it is a benchmark-only change, reset on down/up).
BSRV=$(docker exec "$CLIENT" wg show wg0 peers | head -n1)
docker exec "$CLIENT" wg set wg0 peer "$BSRV" allowed-ips "10.20.0.1/32,10.10.10.20/32"

# Throughput: iperf3 to the server's tunnel address, so we measure the encrypted
# path itself, before the forwarding firewall.
echo "-- throughput (iperf3, 10s) --"
docker exec -d "$GW" sh -c "iperf3 -s -1 -B $TUNNEL_SERVER_IP >/tmp/iperf.log 2>&1" || true
sleep 1
docker exec "$CLIENT" iperf3 -c "$TUNNEL_SERVER_IP" -t 10 -f m | awk '/receiver/ {print "  throughput:", $(NF-2), $(NF-1)}'

# Latency over the tunnel.
echo "-- latency (ping x20 over tunnel) --"
docker exec "$CLIENT" ping -c 20 -q "$TUNNEL_SERVER_IP" | awk -F'[/=]' '/rtt|round-trip/ {print "  rtt avg:", $5, "ms"}'

# Handshake time: tear the tunnel down and back up, time to first handshake.
echo "-- handshake establishment --"
docker exec "$CLIENT" wg-quick down wg0 >/dev/null 2>&1 || true
start=$(date +%s.%N)
docker exec "$CLIENT" wg-quick up wg0 >/dev/null 2>&1
# Poll until the latest-handshake epoch is non-zero.
for _ in $(seq 1 50); do
    hs=$(docker exec "$CLIENT" sh -c "wg show wg0 latest-handshakes | awk '{print \$2}'" 2>/dev/null || echo 0)
    [ "${hs:-0}" != 0 ] && break
    sleep 0.2
done
end=$(date +%s.%N)
echo "  handshake established in $(awk "BEGIN{printf \"%.2f\", $end-$start}") s"

# Footprint: memory of each lab container.
echo "-- container memory footprint --"
docker stats --no-stream --format "  {{.Name}}: {{.MemUsage}}" \
    zt-wg-server zt-client-alice zt-client-bob zt-svc-web zt-svc-db 2>/dev/null || true

echo "Record these in docs/benchmark-results.md. For an OpenVPN comparison row,"
echo "stand up the OpenVPN container profile and re-run the same three measures."
