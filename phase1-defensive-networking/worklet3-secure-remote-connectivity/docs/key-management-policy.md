# Key Management Policy

Each peer generates its own keypair locally, private keys never leave the host.
Public keys are exchanged out of band, not over the tunnel being established.
Private key files are set to permission 600, owned by root, stored under /etc/wireguard.
Key rotation: regenerate and redistribute public keys every 90 days or on suspected compromise.
Revocation: remove the peer block from the server config and run wg syncconf to revoke immediately.

## Threat Model, STRIDE-lite

Spoofing: A stolen client private key lets an attacker impersonate that client. Mitigated by one keypair per device, permission 600, 90 day rotation, and immediate revocation with wg syncconf.
Information Disclosure: Tunnel traffic is encrypted with ChaCha20-Poly1305, so it cannot be read on the WAN path.
Tampering: Every packet is authenticated, and replayed packets are rejected using a per-session counter.
Denial of Service: The server sends no reply to packets that are not from a known peer, so a UDP scan cannot tell WireGuard is listening. Under load, the server answers handshakes with a cookie the client must echo from its real IP before the server does the expensive key exchange.
Elevation of Privilege: A compromised client becomes a foothold inside the network. Limit what the tunnel can reach with a firewall rule on the server that only lets 10.20.0.0/24 reach the internal web server on TCP 80 and 443, not the whole of 10.10.10.0/24.
Residual risk: Possession of the key is the only factor, there is no per-user MFA on the tunnel. An optional PresharedKey per peer adds protection against future quantum attacks on Curve25519.
