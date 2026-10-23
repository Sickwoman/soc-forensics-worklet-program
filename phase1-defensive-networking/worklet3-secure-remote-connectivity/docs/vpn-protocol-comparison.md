# VPN Protocol Comparison, WireGuard vs OpenVPN vs IPsec/IKEv2

This replaces the earlier two-way note with a scored comparison across the three
remote-access options the evaluator asked about, judged against criteria that
matter for a defended, monitored deployment rather than on preference.

## Scoring matrix

Scores are 1 low to 5 high, higher is better for a secure remote-access gateway.

| Criterion | WireGuard | OpenVPN | IPsec/IKEv2 |
|---|---|---|---|
| Small attack surface (codebase) | 5 (~4k lines) | 2 (~100k + OpenSSL) | 2 (large, kernel + daemon) |
| Crypto model | 5 (fixed modern suite) | 3 (TLS, configurable, can be weakened) | 3 (strong, many knobs to misset) |
| Performance | 5 (in-kernel, low overhead) | 3 (userspace) | 4 (in-kernel) |
| NAT traversal | 4 (UDP, roaming) | 4 (UDP or TCP 443) | 3 (needs NAT-T, UDP 4500) |
| Auth and identity model | 2 (static keys only) | 4 (per-user certs, PKI, CRL, EAP) | 4 (certs or EAP, MFA via RADIUS) |
| Auditability out of the box | 2 (no logs) | 4 (connect/disconnect logs) | 3 (daemon logs) |
| Operational simplicity | 5 (keypairs, tiny config) | 2 (PKI to run) | 2 (complex policy) |
| Runs on the pfSense gateway | 5 (native package) | 5 (native, mature) | 5 (native) |

## Where each one wins

- WireGuard: the smallest attack surface, the simplest crypto that cannot be
  misconfigured into weakness, the best performance, and the least to operate.
  Its weaknesses are no built-in per-user identity and no logging.
- OpenVPN: the strongest native identity story, real per-user certificates with a
  PKI and a certificate revocation list, username and password or MFA through
  plugins, and useful connect and disconnect logs. The cost is a large TLS and
  OpenSSL attack surface and the PKI to run.
- IPsec/IKEv2: a mature standard with the best interoperability and native client
  support on Windows, macOS, and mobile, and certificate or RADIUS-backed MFA. The
  cost is configuration complexity and a large footprint.

## Reading it against the threat model

The key-management-policy.md threat model prioritises a small attack surface,
crypto that cannot be weakened, and limiting the blast radius of a stolen
credential. WireGuard wins the first two outright. It loses on identity and
logging, which are precisely the two gaps the evaluator raised. Rather than switch
to a heavier protocol to buy those features, this worklet keeps WireGuard's thin,
fast, hard-to-misconfigure core and adds the two missing pieces around it:

- Identity, per-peer entitlements enforced in nftables and a device posture gate,
  see zero-trust-architecture.md.
- Logging, scripts/wg-monitor.py plus the SIEM bridge, see
  monitoring-and-detection.md.

The result keeps WireGuard's 5s on attack surface, crypto, performance, and
simplicity while raising its identity and auditability scores through the Zero
Trust layer, instead of inheriting OpenVPN's and IPsec's attack surface to get
them.

## Choice

WireGuard as the transport, wrapped in the Zero Trust access and monitoring layer.
OpenVPN is the right alternative if hard per-user certificate identity with a CRL
is a firm requirement and the extra attack surface is acceptable; its measured row
in docs/benchmark-results.md is there to make that trade-off concrete. On the
production pfSense gateway all three are available as native packages, so the same
decision holds there.
