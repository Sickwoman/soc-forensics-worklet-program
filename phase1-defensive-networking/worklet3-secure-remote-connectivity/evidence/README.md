# Worklet 3 Evidence

Runtime evidence from an actual run of the lab, not static checks. Captured on a
WSL2 Ubuntu 24.04 dry-run environment (kernel 6.18, Docker 29.1), which is NOT the
8 GB target VM, so the benchmark figures are indicative only. The pass/fail of the
security behaviours is environment-independent and holds on any Docker host.

- 00-environment.txt — the host the evidence was captured on.
- 01-verification-run.txt — the eight-behaviour verification: least privilege both
  ways, unauthorized access blocked, a route-widening bypass attempt blocked at the
  gateway (deny counter 0 to 4), detection of the pivot, live revocation of alice
  with bob unaffected, and policy surviving a restart.
- 02-demo-run.txt — a full transcript of scripts/demo.sh (the three-scene live
  demo), suitable as the recording fallback.
- 03-benchmark-wsl.txt — scripts/benchmark.sh output (throughput, latency,
  handshake, memory). Dry-run numbers; re-run on the VM for real figures.

To regenerate on the target VM:
  bash scripts/lab-up.sh up
  bash scripts/demo.sh --auto | tee evidence/02-demo-run.txt
  bash scripts/benchmark.sh   | tee evidence/03-benchmark-vm.txt

No private keys or secrets are included; WireGuard public keys are not sensitive.
