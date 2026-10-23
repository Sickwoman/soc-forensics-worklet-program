# Worklet 3 Verification Report

Date: 2026-10-07. Environment: WSL2 Ubuntu 24.04, kernel 6.18, Docker 29.1 (a
dry-run Docker host, NOT the 8 GB target VM). Raw evidence in evidence/.

## What passed (real runtime, environment-independent)

| # | Behaviour | Result | Evidence |
|---|---|---|---|
| 1 | alice (developer) reaches the web app | ALLOWED, HTTP 200 | 01, 02 |
| 2 | bob (dba) reaches the database | ALLOWED, db-ok | 01, 02 |
| 3 | alice blocked from the database | BLOCKED | 01, 02 |
| 4 | bob blocked from the web app | BLOCKED (timeout) | 01, 02 |
| 5 | widened client cannot bypass the gateway | BLOCKED, deny counter 0 to 4 | 01, 02 |
| 6 | pivot attempt is detected | denied_traffic alert, severity high | 01, 02 |
| 7 | revoking alice drops her live, bob unaffected | alice blocked, 2 peers left, bob ok | 01 |
| 8 | restart preserves the access policy | alice web ok, alice db blocked | 01 |

Spoofing prevention (identity cannot be forged) is demonstrated by behaviour 5:
the client's source tunnel IP is cryptographically bound to its key, so widening
its routes did not let it impersonate another identity or reach another service.

## Bugs found by running it, and fixed

All five would also affect a real VM deployment; fixed in commit 140886c.
1. Compose built the shared image from five services in parallel and raced.
2. Gateway internal IP 10.10.10.1 collided with the Docker bridge gateway.
3. No return route for internal services to tunnel clients, added NAT masquerade.
4. wg-quick PostUp sysctl aborted on the read-only /proc/sys in a container.
5. Single-file bind mount of peers.yaml meant live revocation was not seen by the
   gateway, switched to a directory mount.

## Benchmarks

Dry-run figures only (WSL2, 16 cores, not the VM): ~683 Mbit/s, 0.38 ms RTT, 0.37 s
handshake, gateway ~11 MiB, whole lab ~38 MiB. See docs/benchmark-results.md. The
tiny footprint strongly indicates the 8 GB target is fine, but this must be
confirmed by running scripts/benchmark.sh on the VM.

## Not yet done / untested

- The lab has NOT been run on the 8 GB target VM. Do a dress rehearsal there:
  install Docker and the host wireguard module, then lab-up.sh up and demo.sh.
- Real benchmark figures on the VM.
- The device posture gate is wired in but its three checks are environment-driven
  stubs, not real device probes. See zero-trust-architecture.md.
- Wazuh SIEM ingest and running on pfSense are documented designs, not built.

## Readiness

The Zero Trust controls, detection, live revocation, and restart behaviour are
functionally verified on a Docker host. Before the review: run the dress
rehearsal and capture benchmarks on the 8 GB VM, and keep evidence/02-demo-run.txt
(or a screen recording) as the fallback. Not review-ready until the VM dress
rehearsal passes.
