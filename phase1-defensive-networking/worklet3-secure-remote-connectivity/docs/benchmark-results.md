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

## Results

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
