# Worklet 3: Secure Remote Connectivity, Zero Trust WireGuard

Objective: Provide encrypted remote access that follows Zero Trust, each identity
reaches only the services its role needs, the tunnel is monitored, and access can
be revoked live. WireGuard is the transport; the identity, least-privilege, and
monitoring layers are what make it Zero Trust rather than a flat VPN.

This worklet was rebuilt after review feedback: justify the protocol choice
against OpenVPN and IPsec, and add monitoring and a demonstrated attack with
recovery. See docs/zero-trust-architecture.md for the why.

## Lab Topology

  Remote clients on the untrusted edge network, 172.28.0.0/24
    alice, developer   -> web app only
    bob, database admin -> database only
    mallory, contractor -> web app (a compromised laptop, used in the demo)
      WireGuard tunnel, UDP 51820, to the Zero Trust gateway (wg-server)
        tunnel network 10.20.0.0/24, nftables enforces per-identity entitlements
          internal services on 10.10.10.0/24: web 10.10.10.20:80, db 10.10.10.30:5432

The whole scenario is six small containers inside one Linux VM, so it runs on an
8 GB laptop. That efficiency is deliberate, not a compromise, see
docs/benchmark-results.md.

## Build Steps

1. On the lab VM, install Docker Engine with the compose plugin, and ensure the
   host kernel has the wireguard module, modprobe wireguard.
2. Review config/peers.yaml, the identity registry: each peer's user, role,
   device, the services it may reach, and its expiry. This one file drives the
   server config and the firewall through scripts/render-config.py.
3. Bring the lab up: bash scripts/lab-up.sh up. The server container generates all
   keys into a shared volume, renders wg0.conf and the nftables ruleset from the
   registry, and raises the tunnels.
4. Check it: bash scripts/lab-up.sh status shows the entitlements and connected
   peers.
5. Onboard or re-enable a peer after a posture check: bash scripts/provision-peer.sh
   <user>. Revoke one live: bash scripts/revoke-peer.sh <user>.
6. Watch the tunnel: python3 scripts/wg-monitor.py --interval 5, see
   docs/monitoring-and-detection.md.

## The demo

  bash scripts/demo.sh

Five minutes, three scenes: least privilege (access follows identity), attack and
detection (a stealthy endpoint, a blocked pivot, a monitor alert), and respond and
recover (revoke a compromised peer live while others stay connected). The script
and the fallback plan are in docs/demo-runbook.md.

## Documentation in this worklet

- docs/zero-trust-architecture.md, the design, the two control layers, posture,
  and the pfSense production path.
- docs/vpn-protocol-comparison.md, the scored WireGuard vs OpenVPN vs IPsec matrix.
- docs/monitoring-and-detection.md, what is watched and the SIEM bridge.
- docs/key-management-policy.md, key lifecycle, automation, and the threat model.
- docs/benchmark-results.md, measured throughput, latency, handshake, footprint.
- docs/demo-runbook.md, how to run the live demo and what to do if it breaks.

## Evidence to capture

- lab-up.sh status output, the loaded entitlements and the connected peers.
- Scene 1, alice reaching web and blocked from db, bob the reverse.
- Scene 2, the port scan getting no response, and the wg-monitor denied_traffic
  alert for the blocked pivot.
- Scene 3, the wg show before and after revocation, mallory gone, alice still up.
- A recording of a full demo run, as the review fallback.
- Fill the benchmark table in docs/benchmark-results.md.

Keep real keys and the generated configs out of the repo, the .gitignore already
blocks them, see docs/evidence-guide.md.

## Lessons Learned / Limitations

Fill in after the lab run. Known limitations are listed at the end of
docs/zero-trust-architecture.md, key possession is still the primary factor, and
the posture gate and local monitor are teaching models with the production
equivalents named.
