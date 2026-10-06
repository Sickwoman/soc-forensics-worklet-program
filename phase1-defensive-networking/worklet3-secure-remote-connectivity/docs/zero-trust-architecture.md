# Zero Trust Remote Access Architecture

## Why this worklet changed

The first version of this worklet stood up a WireGuard tunnel and proved it came
up. That is a flat VPN: once a key connects, it can reach the whole internal
subnet. The old client template literally routed 10.10.10.0/24 into the tunnel,
so one stolen laptop reached every internal host. A plain VPN authenticates the
device once at the edge and then trusts it everywhere, which is exactly the
assumption Zero Trust removes.

This version keeps WireGuard as the transport, because its crypto and small
attack surface are excellent, but wraps it in a Zero Trust access model: every
request is tied to an identity, and each identity reaches only the services its
role needs, re-checked at the gateway on every connection.

## The three ideas

1. Identity, not just a device, defines reach. Each peer in config/peers.yaml has
   a user, a role, a device, an allow list of services, and an expiry.
2. Least privilege is enforced, not assumed. The gateway firewall denies by
   default and permits only each peer's listed services.
3. Access is revocable and watched. A peer can be revoked live, and the tunnel
   is monitored so misuse is detected, see docs/monitoring-and-detection.md.

## Topology

  Remote clients on the untrusted edge, 172.28.0.0/24
    alice, developer, device laptop-alice-01
    bob, database admin, device laptop-bob-01
    mallory, contractor, device laptop-mallory-01
      each builds a WireGuard tunnel, UDP 51820, to
        the Zero Trust gateway, wg-server
          wg0 tunnel network 10.20.0.0/24
          nftables enforces per-identity entitlements on the forward path
            internal services, 10.10.10.0/24
              web app   10.10.10.20 tcp 80
              database  10.10.10.30 tcp 5432

alice reaches the web app only, bob reaches the database only. Same tunnel,
different reach, decided by identity.

## Two independent layers of control

WireGuard AllowedIPs and the nftables ruleset do different jobs, and separating
them is what makes this Zero Trust rather than a VPN with a firewall bolted on.

- WireGuard AllowedIPs is cryptographic routing. On the server, a peer's
  AllowedIPs is only its own tunnel address, for example 10.20.0.2/32, which binds
  one key to one tunnel IP and decides which packets that key is allowed to send.
- nftables is authorization. The forward chain defaults to drop and permits only
  the service each tunnel IP is entitled to reach. This is re-evaluated for every
  connection, which is the "never trust, always verify" part.

Because the two layers are independent, a tampered or over-broad client config
cannot widen access: even if a client sets AllowedIPs to the whole subnet, the
gateway still only forwards it to its one permitted service. Defense does not
depend on the client behaving.

## Device posture

Before a device is onboarded, scripts/posture-check.sh runs on it and must pass,
currently disk encryption on, host firewall on, and OS patched. provision-peer.sh
refuses a device that fails. The checks here are lab-grade stubs driven by the
environment so the demo can show a refusal; on a real endpoint each stub is
replaced by a genuine probe or a feed from an MDM. The point being taught is that
identity plus device state gate access together, not identity alone.

## Mapping to Zero Trust principles

- Verify explicitly: key-authenticated identity plus a device posture check.
- Least privilege: default-drop firewall, one accept per entitlement, short expiry.
- Assume breach: mallory is treated as already compromised, and the design limits
  the blast radius to her one entitled service and lets her be revoked in seconds.

## Running it on the pfSense gateway, the production path

In the lab the gateway is a container so the whole thing fits on 8 GB. In
production the same design runs on the Worklet 1 pfSense box, so remote access
terminates on the perimeter firewall rather than a separate server:

- pfSense has a native WireGuard package, VPN, WireGuard, that provides the
  tunnel interface and peers through the GUI.
- The per-identity rules live in the pfSense firewall rules on the WireGuard
  interface, one pass rule per entitlement, a default block at the bottom, which
  is the same model as nftables-zerotrust.nft expressed in pfSense's own rules.
- pfSense logs those rules to its firewall log, which Worklet 4 already forwards
  to the SIEM by syslog, so the monitoring path is reused rather than rebuilt.

Terminating the tunnel on the gateway also means remote traffic lands in the
correct VLAN from Worklet 2 and is subject to the same egress policy as everything
else, instead of bypassing the perimeter through a side door.

## Honest limitations

- Possession of the key is still the primary factor. Add a per-peer PresharedKey,
  and SSH keys plus TOTP from Worklet 6 for the services behind the tunnel.
- The posture gate and the local monitor are teaching models, not a commercial
  ZTNA product. The real-world equivalents are an identity-aware proxy, an MDM,
  and the full SIEM.
- A real deployment resolves services by name and segments further; the lab uses
  fixed addresses to stay readable.
