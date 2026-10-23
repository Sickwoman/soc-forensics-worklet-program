#!/usr/bin/env bash
# Container entrypoint for the Zero Trust lab. Behaviour is chosen by the ROLE
# env var set in docker-compose.yml: server, client, or db.
# Keys are shared between containers through the /lab-keys volume: the server
# generates every keypair once, the clients read what they need.
set -euo pipefail

REGISTRY="${REGISTRY:-/etc/zerotrust/peers.yaml}"
KEYS=/lab-keys
umask 077
mkdir -p "$KEYS" /etc/wireguard

active_users() {
    python3 -c "import yaml;print(' '.join(p['user'] for p in yaml.safe_load(open('$REGISTRY'))['peers'] if p.get('status','active')=='active'))"
}

genkey_if_absent() {
    local name="$1"
    if [ ! -f "$KEYS/$name.key" ]; then
        wg genkey | tee "$KEYS/$name.key" | wg pubkey > "$KEYS/$name.pub"
    fi
}

case "${ROLE:?set ROLE to server, client, or db}" in

server)
    genkey_if_absent server
    for u in $(active_users); do genkey_if_absent "$u"; done
    render-config.py --server --keys-dir "$KEYS" --registry "$REGISTRY" > /etc/wireguard/wg0.conf
    render-config.py --nft --registry "$REGISTRY" > /etc/wireguard/nftables-zerotrust.nft
    chmod 600 /etc/wireguard/wg0.conf
    wg-quick up wg0
    echo "[server] wg0 up, entitlements loaded:"
    nft list table inet zerotrust || true
    wg show
    exec sleep infinity
    ;;

client)
    user="${PEER_USER:?set PEER_USER for a client}"
    echo "[client $user] waiting for keys..."
    for _ in $(seq 1 60); do
        [ -f "$KEYS/server.pub" ] && [ -f "$KEYS/$user.key" ] && break
        sleep 1
    done
    if [ ! -f "$KEYS/server.pub" ] || [ ! -f "$KEYS/$user.key" ]; then
        echo "[client $user] keys never appeared, is the server up?" >&2
        exit 1
    fi
    render-config.py --client "$user" --keys-dir "$KEYS" --registry "$REGISTRY" > /etc/wireguard/wg0.conf
    chmod 600 /etc/wireguard/wg0.conf
    wg-quick up wg0
    echo "[client $user] tunnel up:"
    wg show
    exec sleep infinity
    ;;

db)
    # Minimal stand-in for an internal database: anything that connects to 5432
    # gets a one-line banner, which is enough to prove reachability or blocking.
    echo "[db] listening on 5432"
    exec socat -d TCP-LISTEN:5432,fork,reuseaddr SYSTEM:"echo db-ok"
    ;;

*)
    echo "unknown ROLE: $ROLE" >&2
    exit 1
    ;;
esac
