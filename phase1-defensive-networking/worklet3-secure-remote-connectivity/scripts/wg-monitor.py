#!/usr/bin/env python3
"""
Watch the WireGuard gateway and raise alerts, because stock WireGuard keeps no
connection log of its own. It reads `wg show dump`, the nftables deny counter,
and the key registry, and reports anomalies as JSON lines plus syslog, so the
same events can later be shipped to the Worklet 4 SIEM.

Detections:
  unknown_peer    a connected key that is not an active user in peers.yaml
  endpoint_change a peer's source address changed, possible key reuse elsewhere
  expired_peer    a connected peer whose entitlement expiry has passed
  denied_traffic  the Zero Trust firewall dropped traffic since the last poll
  stale_handshake a configured peer with no recent handshake (informational)

Usage:
  wg-monitor.py --once                 one pass, using the lab container
  wg-monitor.py --interval 5           poll every 5 seconds
  wg-monitor.py --gateway local        read wg/nft on this host instead of docker
  wg-monitor.py --self-test            run the parser and detector on sample data
Requires PyYAML, standard library otherwise.
"""
import argparse
import datetime
import json
import os
import subprocess
import sys
import time

try:
    import yaml
except ImportError:
    yaml = None

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_REGISTRY = os.path.join(HERE, "..", "config", "peers.yaml")
STALE_HANDSHAKE_SECONDS = 180


# ---- pure parsing and detection (unit-testable, no I/O) --------------------

def parse_wg_dump(text):
    """Parse `wg show <if> dump`. The first line is the interface (4 fields),
    each following line is a peer (8 tab-separated fields)."""
    peers = []
    for line in text.splitlines():
        f = line.split("\t")
        if len(f) != 8:
            continue
        peers.append({
            "public_key": f[0],
            "endpoint": f[2],
            "allowed_ips": f[3],
            "latest_handshake": int(f[4]) if f[4].isdigit() else 0,
            "rx": int(f[5]) if f[5].isdigit() else 0,
            "tx": int(f[6]) if f[6].isdigit() else 0,
        })
    return peers


def parse_deny_packets(nft_text):
    """Pull the packet count off the ZT-DENY log/counter rule."""
    for line in nft_text.splitlines():
        if "ZT-DENY" in line and "packets" in line:
            toks = line.split()
            try:
                return int(toks[toks.index("packets") + 1])
            except (ValueError, IndexError):
                return 0
    return 0


def detect(peers, keymap, active, now_epoch, today, deny_packets, prev):
    """Compare the current gateway state with the previous poll and return a
    list of alert dicts. Pure function: all inputs are plain data."""
    alerts = []
    prev_endpoints = prev.get("endpoints", {})
    prev_deny = prev.get("deny_packets", 0)
    new_endpoints = {}

    for p in peers:
        user = keymap.get(p["public_key"])
        if user is None:
            alerts.append({"type": "unknown_peer", "severity": "high",
                           "detail": "connected key not in registry",
                           "public_key": p["public_key"][:16] + "...",
                           "endpoint": p["endpoint"]})
            continue
        if user not in active:
            alerts.append({"type": "unknown_peer", "severity": "high",
                           "detail": "revoked peer still present on gateway",
                           "user": user, "endpoint": p["endpoint"]})
            continue

        if p["endpoint"] and p["endpoint"] != "(none)":
            new_endpoints[user] = p["endpoint"]
            old = prev_endpoints.get(user)
            if old and old != p["endpoint"]:
                alerts.append({"type": "endpoint_change", "severity": "medium",
                               "user": user, "from": old, "to": p["endpoint"],
                               "detail": "peer source address changed"})

        expiry = active[user].get("expiry")
        if expiry and str(today) > str(expiry) and p["latest_handshake"] > 0:
            alerts.append({"type": "expired_peer", "severity": "medium",
                           "user": user, "expiry": str(expiry),
                           "detail": "connected past entitlement expiry"})

        if p["latest_handshake"] and now_epoch - p["latest_handshake"] > STALE_HANDSHAKE_SECONDS:
            alerts.append({"type": "stale_handshake", "severity": "info",
                           "user": user,
                           "age_seconds": now_epoch - p["latest_handshake"]})

    if deny_packets > prev_deny:
        alerts.append({"type": "denied_traffic", "severity": "high",
                       "new_drops": deny_packets - prev_deny,
                       "total_drops": deny_packets,
                       "detail": "traffic hit the Zero Trust deny rule, "
                                 "a peer reached outside its entitlement",
                       "connected": sorted(new_endpoints)})

    state = {"endpoints": new_endpoints, "deny_packets": deny_packets}
    return alerts, state


# ---- gateway I/O -----------------------------------------------------------

def gw_runner(gateway):
    container = gateway.split(":", 1)[1] if gateway.startswith("docker:") else None

    def run(cmd):
        full = (["docker", "exec", container] + cmd) if container else cmd
        return subprocess.run(full, capture_output=True, text=True, check=True).stdout
    return run


def gather(run, registry_in_gw):
    dump = run(["wg", "show", "wg0", "dump"])
    nft = run(["nft", "list", "table", "inet", "zerotrust"])
    keytext = run(["sh", "-c",
                   'for f in /lab-keys/*.pub; do echo "$(basename "$f" .pub) $(cat "$f")"; done'])
    keymap = {}
    for line in keytext.splitlines():
        parts = line.split()
        if len(parts) == 2:
            keymap[parts[1]] = parts[0]
    return parse_wg_dump(dump), parse_deny_packets(nft), keymap


def load_active(registry_path):
    with open(registry_path, encoding="utf-8") as f:
        reg = yaml.safe_load(f)
    return {p["user"]: p for p in reg["peers"] if p.get("status", "active") == "active"}


# ---- emit ------------------------------------------------------------------

def emit(alerts, to_syslog):
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    for a in alerts:
        a["time"] = stamp
        a["source"] = "wg-monitor"
        line = json.dumps(a, sort_keys=True)
        print(line, flush=True)
        if to_syslog:
            try:
                subprocess.run(["logger", "-t", "wg-monitor", line], check=False)
            except FileNotFoundError:
                pass


# ---- self test --------------------------------------------------------------

def self_test():
    iface = "PRIVKEY\tPUBKEY\t51820\toff"
    alice = "AKEY\t(none)\t172.28.0.21:4444\t10.20.0.2/32\t1000\t10\t20\t25"
    rogue = "ZKEY\t(none)\t172.28.0.99:5555\t10.20.0.9/32\t1000\t1\t1\t0"
    peers = parse_wg_dump("\n".join([iface, alice, rogue]))
    assert len(peers) == 2, peers
    assert parse_deny_packets("x ZT-DENY y counter packets 7 bytes 400") == 7

    keymap = {"AKEY": "alice", "ZKEY": "mallory"}
    active = {"alice": {"expiry": "2099-01-01"}}  # mallory not active, alice fine
    prev = {"endpoints": {"alice": "172.28.0.21:1111"}, "deny_packets": 2}
    alerts, state = detect(peers, keymap, active, now_epoch=1100,
                           today=datetime.date(2026, 10, 6), deny_packets=5, prev=prev)
    kinds = sorted(a["type"] for a in alerts)
    # expect: endpoint_change (alice), unknown_peer (mallory revoked), denied_traffic
    assert kinds == ["denied_traffic", "endpoint_change", "unknown_peer"], kinds
    assert state["deny_packets"] == 5
    print("self-test OK:", kinds)


# ---- main ------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--gateway", default="docker:zt-wg-server",
                    help="docker:<container> (default) or local")
    ap.add_argument("--registry", default=DEFAULT_REGISTRY)
    ap.add_argument("--interval", type=float, default=0.0)
    ap.add_argument("--once", action="store_true")
    ap.add_argument("--state-file", default=os.path.join(HERE, ".wg-monitor-state.json"))
    ap.add_argument("--no-syslog", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        self_test()
        return
    if yaml is None:
        sys.exit("PyYAML is required: pip install pyyaml, or apk add py3-yaml")

    run = gw_runner(args.gateway)

    def load_state():
        try:
            with open(args.state_file, encoding="utf-8") as f:
                return json.load(f)
        except (OSError, ValueError):
            return {"endpoints": {}, "deny_packets": 0}

    def one_pass():
        peers, deny, keymap = gather(run, args.registry)
        active = load_active(args.registry)
        alerts, state = detect(peers, keymap, active,
                               int(time.time()), datetime.date.today(), deny, load_state())
        emit(alerts, to_syslog=not args.no_syslog)
        with open(args.state_file, "w", encoding="utf-8") as f:
            json.dump(state, f)
        return alerts

    if args.once or args.interval <= 0:
        one_pass()
        return
    while True:
        try:
            one_pass()
        except subprocess.CalledProcessError as e:
            print(json.dumps({"type": "monitor_error", "detail": e.stderr.strip()}), flush=True)
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
