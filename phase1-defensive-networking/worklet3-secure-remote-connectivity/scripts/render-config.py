#!/usr/bin/env python3
"""
Render the server config, a client config, or the nftables firewall from the
identity registry config/peers.yaml, so network reach is defined by identity in
one place instead of edited by hand in three.

Usage:
  render-config.py --server   [--keys-dir DIR]   print the server wg0.conf
  render-config.py --nft      [--keys-dir DIR]   print the nftables ruleset
  render-config.py --client USER [--keys-dir DIR]  print that user's wg0.conf

Public keys come from --keys-dir/<name>.pub when that directory is given, which
is how the container lab distributes freshly generated keys, otherwise from the
public_key field in peers.yaml, which is how a real deployment pins them.
Requires PyYAML, standard library otherwise.
"""
import argparse
import os
import sys

try:
    import yaml
except ImportError:
    sys.exit("PyYAML is required: pip install pyyaml, or apk add py3-yaml")

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_REGISTRY = os.path.join(HERE, "..", "config", "peers.yaml")


def load_registry(path):
    with open(path, encoding="utf-8") as f:
        reg = yaml.safe_load(f)
    for key in ("server", "internal_services", "peers"):
        if key not in reg:
            sys.exit("peers.yaml is missing the " + key + " section")
    return reg


def active_peers(reg):
    return [p for p in reg["peers"] if p.get("status", "active") == "active"]


def pubkey(name, field_value, keys_dir):
    # Prefer a key file from the lab keys dir, fall back to the registry field.
    if keys_dir:
        path = os.path.join(keys_dir, name + ".pub")
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                return f.read().strip()
    return field_value


def privkey(name, keys_dir, fallback):
    if keys_dir:
        path = os.path.join(keys_dir, name + ".key")
        if os.path.exists(path):
            with open(path, encoding="utf-8") as f:
                return f.read().strip()
    return fallback


def services_for(peer, reg):
    out = []
    for name in peer.get("allow", []):
        svc = reg["internal_services"].get(name)
        if svc is None:
            sys.exit("peer " + peer["user"] + " allows unknown service " + name)
        out.append((name, svc))
    return out


def render_server(reg, keys_dir):
    srv = reg["server"]
    lines = [
        "[Interface]",
        "Address = " + srv["address"],
        "ListenPort = " + str(srv["endpoint"].split(":")[-1]),
        "PrivateKey = " + privkey("server", keys_dir, "SERVER_PRIVATE_KEY_HERE"),
        "",
        "PostUp = sysctl -w net.ipv4.ip_forward=1",
        "PostUp = nft -f /etc/wireguard/nftables-zerotrust.nft",
        "PostDown = nft delete table inet zerotrust || true",
        "",
    ]
    for peer in active_peers(reg):
        allow = ",".join(peer.get("allow", []))
        lines += [
            "[Peer]",
            "# user=" + peer["user"] + " role=" + peer.get("role", "?") +
            " device=" + peer.get("device_id", "?") + " allow=" + allow,
            "PublicKey = " + pubkey(peer["user"], peer.get("public_key", ""), keys_dir),
            "AllowedIPs = " + peer["tunnel_ip"] + "/32",
            "",
        ]
    return "\n".join(lines)


def render_client(reg, user, keys_dir):
    srv = reg["server"]
    peer = next((p for p in reg["peers"] if p["user"] == user), None)
    if peer is None:
        sys.exit("no peer named " + user + " in peers.yaml")
    # Scope the tunnel to only the services this user is entitled to.
    allowed = [svc["host"] + "/32" for _, svc in services_for(peer, reg)]
    lines = [
        "[Interface]",
        "Address = " + peer["tunnel_ip"] + "/24",
        "PrivateKey = " + privkey(user, keys_dir, "CLIENT_PRIVATE_KEY_HERE"),
        "",
        "[Peer]",
        "PublicKey = " + pubkey("server", srv.get("public_key", ""), keys_dir),
        "Endpoint = " + srv["endpoint"],
        "AllowedIPs = " + ", ".join(allowed),
        "PersistentKeepalive = 25",
        "",
    ]
    return "\n".join(lines)


def render_nft(reg):
    lines = [
        "#!/usr/sbin/nft -f",
        "# Zero Trust least-privilege firewall for the WireGuard gateway.",
        "# GENERATED from config/peers.yaml by scripts/render-config.py, do not edit by hand.",
        "# Loaded by the PostUp line in wg0-server.conf. Default policy is drop, so a peer",
        "# can only reach a service that has an explicit accept rule below.",
        "",
        "table inet zerotrust {",
        "    chain forward {",
        "        type filter hook forward priority filter; policy drop;",
        "",
        "        # Let replies and ongoing flows back through.",
        "        ct state established,related accept",
        "",
        "        # Per-peer entitlements, one accept per allowed service, generated from",
        "        # each active peer's allow list in peers.yaml.",
    ]
    for peer in active_peers(reg):
        for name, svc in services_for(peer, reg):
            lines.append(
                "        ip saddr " + peer["tunnel_ip"] +
                " ip daddr " + svc["host"] +
                " " + svc["proto"] + " dport " + str(svc["port"]) +
                " ct state new accept"
                "   # " + peer["user"] + " -> " + name)
    lines += [
        "",
        "        # Anything else arriving from the tunnel is outside the peer's entitlement.",
        "        # Log it with a counter, then the drop policy takes it. The ZT-DENY prefix",
        "        # is what scripts/wg-monitor.py watches for to raise a denied-traffic alert.",
        '        iifname "wg0" log prefix "ZT-DENY " level warn counter',
        "    }",
        "}",
        "",
    ]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--server", action="store_true")
    mode.add_argument("--nft", action="store_true")
    mode.add_argument("--client", metavar="USER")
    ap.add_argument("--keys-dir")
    ap.add_argument("--registry", default=DEFAULT_REGISTRY)
    args = ap.parse_args()

    reg = load_registry(args.registry)
    if args.server:
        sys.stdout.write(render_server(reg, args.keys_dir))
    elif args.nft:
        sys.stdout.write(render_nft(reg))
    else:
        sys.stdout.write(render_client(reg, args.client, args.keys_dir))


if __name__ == "__main__":
    main()
