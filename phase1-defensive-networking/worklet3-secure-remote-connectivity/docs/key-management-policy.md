# Key Management Policy

Each peer generates its own keypair locally, private keys never leave the host.
Public keys are exchanged out of band, not over the tunnel being established.
Private key files are set to permission 600, owned by root, stored under /etc/wireguard.
Key rotation: regenerate and redistribute public keys every 90 days or on suspected compromise.
Revocation: run scripts/revoke-peer.sh <user>, which flips the peer to revoked in
config/peers.yaml, re-renders the active set, and applies it with wg syncconf, so
access is withdrawn live without a manual config edit or an interface restart.

## Automation and the identity registry

Keys and entitlements are driven from config/peers.yaml, the single source of
truth, so onboarding, rotation, and revocation are repeatable instead of hand-done.

- Onboard: add the peer to peers.yaml, then scripts/provision-peer.sh <user>,
  which runs a device posture check and applies the new entitlement live.
- Rotate: generate a fresh keypair for the peer, update its public key in
  peers.yaml, and re-run provision-peer.sh. Because the apply is declarative, the
  old key stops working the moment the new set is pushed. Rotate every 90 days or
  on suspected compromise.
- Revoke: scripts/revoke-peer.sh <user>, as above.

scripts/render-config.py turns the registry into the server config and the
firewall, so a peer's access always matches the registry and cannot drift apart
by hand-editing one file and forgetting another.

## Threat Model, STRIDE-lite

Spoofing: A stolen client private key lets an attacker impersonate that client. Mitigated by one keypair per device, permission 600, 90 day rotation, and immediate revocation with wg syncconf.
Information Disclosure: Tunnel traffic is encrypted with ChaCha20-Poly1305, so it cannot be read on the WAN path.
Tampering: Every packet is authenticated, and replayed packets are rejected using a per-session counter.
Denial of Service: The server sends no reply to packets that are not from a known peer, so a UDP scan cannot tell WireGuard is listening. Under load, the server answers handshakes with a cookie the client must echo from its real IP before the server does the expensive key exchange.
Elevation of Privilege: A compromised client becomes a foothold inside the network. Limit what the tunnel can reach with a firewall rule on the server that only lets 10.20.0.0/24 reach the internal web server on TCP 80 and 443, not the whole of 10.10.10.0/24.
Residual risk: Possession of the key is the only factor, there is no per-user MFA on the tunnel. An optional PresharedKey per peer adds protection against future quantum attacks on Curve25519.
