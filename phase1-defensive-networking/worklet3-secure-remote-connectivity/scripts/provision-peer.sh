#!/usr/bin/env bash
# Onboard or re-enable a peer from the identity registry, after a posture check.
# Usage: bash provision-peer.sh <user> [--skip-posture]
#
# Declarative: it re-renders the whole active set from config/peers.yaml and
# applies it live with wg syncconf, so the tunnel is never torn down and other
# users are untouched. Runs against the lab's wg-server container; on a real
# gateway, run the rendered commands (shown by --dry-run) directly instead.
set -euo pipefail
cd "$(dirname "$0")"
REGISTRY=../config/peers.yaml
GW=zt-wg-server

user="${1:?usage: provision-peer.sh <user> [--skip-posture]}"
skip_posture=no
[ "${2:-}" = "--skip-posture" ] && skip_posture=yes

# Peer must exist in the registry.
device_id=$(python3 -c "
import sys,yaml
r=yaml.safe_load(open('$REGISTRY'))
p=next((p for p in r['peers'] if p['user']=='$user'),None)
sys.exit('no such peer: $user') if p is None else print(p.get('device_id','unknown'))
")

# Device posture gate.
if [ "$skip_posture" = no ]; then
    echo "Posture check for $user ($device_id)..."
    if ! docker exec "zt-client-$user" posture-check.sh "$device_id"; then
        echo "REFUSED: $user failed posture, not provisioning." >&2
        exit 2
    fi
fi

# Make sure the peer is active in the registry, then apply the whole set live.
awk -v u="$user" '
  /^[[:space:]]*-[[:space:]]*user:/ { cur=$3 }
  cur==u && /^[[:space:]]*status:/ { sub(/status:[[:space:]]*[A-Za-z]+/, "status: active"); cur="" }
  { print }
' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"

echo "Applying entitlements for all active peers..."
docker exec "$GW" bash -c '
  render-config.py --server --keys-dir /lab-keys --registry /etc/zerotrust/peers.yaml > /etc/wireguard/wg0.conf &&
  render-config.py --nft --registry /etc/zerotrust/peers.yaml > /etc/wireguard/nftables-zerotrust.nft &&
  wg syncconf wg0 <(wg-quick strip wg0) &&
  nft -f /etc/wireguard/nftables-zerotrust.nft
'
echo "Done. $user is provisioned and active."
