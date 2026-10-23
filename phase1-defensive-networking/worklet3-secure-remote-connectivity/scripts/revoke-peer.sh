#!/usr/bin/env bash
# Revoke a peer's access live, with no interface restart and no effect on anyone
# else. This drives the recovery scene in the demo.
# Usage: bash revoke-peer.sh <user>
#
# It flips the peer's status to revoked in config/peers.yaml, re-renders the
# active set, and applies it with wg syncconf, so the revoked tunnel drops within
# one keepalive interval while the other peers stay connected.
set -euo pipefail
cd "$(dirname "$0")"
REGISTRY=../config/peers.yaml
GW=zt-wg-server

user="${1:?usage: revoke-peer.sh <user>}"

python3 -c "
import sys,yaml
r=yaml.safe_load(open('$REGISTRY'))
if not any(p['user']=='$user' for p in r['peers']):
    sys.exit('no such peer: $user')
"

# Flip status to revoked in place, preserving the file's comments and layout.
awk -v u="$user" '
  /^[[:space:]]*-[[:space:]]*user:/ { cur=$3 }
  cur==u && /^[[:space:]]*status:/ { sub(/status:[[:space:]]*[A-Za-z]+/, "status: revoked"); cur="" }
  { print }
' "$REGISTRY" > "$REGISTRY.tmp" && mv "$REGISTRY.tmp" "$REGISTRY"
echo "Marked $user revoked in the registry."

echo "Re-applying the active set live..."
docker exec "$GW" bash -c '
  render-config.py --server --keys-dir /lab-keys --registry /etc/zerotrust/peers.yaml > /etc/wireguard/wg0.conf &&
  render-config.py --nft --registry /etc/zerotrust/peers.yaml > /etc/wireguard/nftables-zerotrust.nft &&
  wg syncconf wg0 <(wg-quick strip wg0) &&
  nft -f /etc/wireguard/nftables-zerotrust.nft
'
echo "Done. $user is revoked. Confirm with: docker exec $GW wg show"
