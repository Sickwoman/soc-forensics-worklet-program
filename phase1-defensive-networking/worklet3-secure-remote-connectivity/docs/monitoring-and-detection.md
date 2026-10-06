# Monitoring and Detection

## The problem

WireGuard is deliberately quiet. It keeps no connection log, writes nothing on a
successful or a failed handshake, and answers nothing to an unauthenticated
packet. That silence is good for stealth but bad for a SOC: out of the box there
is nothing to alert on. This is the gap the evaluator pointed out, and this
worklet closes it by adding the telemetry WireGuard does not produce itself.

## What is observed

scripts/wg-monitor.py polls three sources on the gateway and compares each poll
with the last:

- `wg show wg0 dump` for each peer's current endpoint, last handshake time, and
  bytes transferred.
- The nftables ZT-DENY rule's packet counter, which rises whenever a peer sends
  traffic outside its entitlement.
- The key registry config/peers.yaml, for which identities should be active and
  when each entitlement expires.

## Detections

- unknown_peer, high. A connected key that maps to no active user, either a key
  that is not in the registry at all, or a peer that was revoked but is somehow
  still present. This is the signal that someone is on the tunnel who should not
  be.
- endpoint_change, medium. A peer whose source address changed between polls. The
  same key appearing from a new location can mean the key was copied to another
  device.
- expired_peer, medium. A peer still connecting after its entitlement expiry,
  which should have been deprovisioned.
- denied_traffic, high. The Zero Trust firewall dropped traffic since the last
  poll, so a peer tried to reach a service it is not entitled to, the classic
  lateral-movement attempt. The alert lists who was connected at the time.
- stale_handshake, info. A configured peer with no recent handshake, useful for
  spotting a tunnel that has quietly dropped.

Why these and not "failed handshake": the server never sees a failed or rogue
handshake, because WireGuard does not respond to or log unauthenticated packets.
So the detections are built on what is genuinely observable, the authorization
layer and peer state, rather than on events WireGuard does not emit.

## Output and the SIEM bridge

Every alert is one JSON line on stdout, and also sent to syslog with the tag
wg-monitor when syslog is available. JSON lines keep the demo readable and drop
straight into the Worklet 4 pipeline.

To ship these to the Wazuh SIEM, point the Worklet 4 agent at the monitor's
syslog tag, then add a decoder and rule in the same style as
worklet4-soc-siem/config/wazuh-decoder-example.xml:

  Decoder: match the wg-monitor tag, then JSON-decode the message so each field,
  type, user, severity, becomes searchable.
  Rule: raise the Wazuh alert level by the monitor's severity, for example map a
  denied_traffic or unknown_peer event to level 12, high, so it correlates with
  the brute-force and IDS rules already defined in
  worklet4-soc-siem/docs/alert-severity-levels.md.

On 8 GB the full Wazuh stack is not run next to this lab, so during the demo the
monitor's own output is the alert feed, and the decoder plus rule above are the
documented drop-in for the larger lab. This is a stated constraint, not a gap.

## Using it

  # one pass, reading the lab container
  python3 scripts/wg-monitor.py --once

  # continuous, every 5 seconds
  python3 scripts/wg-monitor.py --interval 5

  # read a real gateway directly instead of the container
  python3 scripts/wg-monitor.py --gateway local --interval 5

  # verify the parser and detector logic with no lab running
  python3 scripts/wg-monitor.py --self-test

## Evidence to capture

- A denied_traffic alert from the monitor when a peer probes outside its
  entitlement, paired with the rising ZT-DENY counter in nft list table inet
  zerotrust.
- An unknown_peer alert for the rogue session in the demo.
- The before and after of revocation, the alert clearing once the peer is removed.
