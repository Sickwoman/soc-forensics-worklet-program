# Key Management Policy

Each peer generates its own keypair locally, private keys never leave the host.
Public keys are exchanged out of band, not over the tunnel being established.
Private key files are set to permission 600, owned by root, stored under /etc/wireguard.
Key rotation: regenerate and redistribute public keys every 90 days or on suspected compromise.
Revocation: remove the peer block from the server config and run wg syncconf to revoke immediately.
