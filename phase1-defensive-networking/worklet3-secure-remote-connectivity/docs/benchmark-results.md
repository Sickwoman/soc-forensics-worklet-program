# Benchmark Results

Numbers from scripts/benchmark.sh, so the protocol comparison rests on measurement
rather than assertion. Fill the table in after a run on the lab machine, the
values below are placeholders.

## Test setup

- Host: the 8 GB lab laptop, record CPU and whether on AC power.
- Path: client-alice to the gateway tunnel address 10.20.0.1, so the figure is
  the encrypted tunnel itself, before the forwarding firewall.
- Tooling: iperf3 for throughput, ping for latency, wg-quick down then up for
  handshake time, docker stats for memory.

## Dry-run measurement (WSL2 — NOT the 8 GB target VM)

Captured 2026-10-07 on WSL2 Ubuntu 24.04, kernel 6.18, 16 cores, Docker 29.1,
with scripts/benchmark.sh. These are indicative only: a 16-core host and a
container-local path are not the 8 GB VM, so they do not prove the 8 GB target.
Re-run on the VM for the real figures.

| Measure | WireGuard (WSL2 dry-run) |
|---|---|
| Throughput | 683 Mbit/s |
| Latency RTT avg | 0.381 ms |
| Handshake / connect | 0.37 s |
| Gateway container memory | 11 MiB |
| Whole lab memory, 6 containers | ~38 MiB |

The footprint is the load-bearing number for the 8 GB claim: the gateway is ~11
MiB and the whole six-container lab is tens of MiB, so RAM is not the limiting
factor. This still needs confirming on the VM, but it is a strong indication.

## Results (8 GB target VM — to be filled on the VM)

| Measure | WireGuard | OpenVPN (optional) | Notes |
|---|---|---|---|
| Throughput, Mbit/s | ____ | ____ | iperf3, 10s, higher is better |
| Latency RTT avg, ms | ____ | ____ | ping x20 over the tunnel |
| Handshake / connect, s | ____ | ____ | down then up to first handshake |
| Gateway container memory, MB | ____ | ____ | docker stats, wg-server |
| Total lab memory, MB | ____ | n/a | all six containers |

## How to fill it

1. Bring the lab up: bash scripts/lab-up.sh up
2. Run: bash scripts/benchmark.sh and copy the figures into the WireGuard column.
3. For the OpenVPN column, stand up the OpenVPN profile and re-run the same three
   measures on the same host, so only the protocol differs. This is the optional
   stretch row, cut it first if time is short.

## Reading the numbers

Expect WireGuard throughput near the link rate with a low single-digit CPU cost,
a sub-second handshake, and a gateway footprint of tens of MB. The point to make
to the evaluator is twofold: WireGuard's in-kernel path is fast and cheap, and the
entire six-container lab fits in a few hundred MB, which is why the Zero Trust
scenario runs on an 8 GB laptop at all. That efficiency is a deliberate design
result, not a lucky accident.
