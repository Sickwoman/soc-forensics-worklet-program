# Program Roadmap to Advanced

The faculty rubric in docs/rubric.md rewards three things at the Advanced level: a
professional threat model, an efficient build, and a functioning model that stops
a real attack and recovers from it. Worklet 3 was rebuilt to hit all three and is
the template; this roadmap is the one upgrade that moves each other worklet the
same way. The pattern is always the same: add a threat model, then demonstrate one
attack being stopped and recovered from, with evidence.

## The pattern, from Worklet 3

- Reframe around a threat, not a tool. Not "set up WireGuard" but "defend remote
  access", which forces the identity, monitoring, and recovery questions.
- Make the build efficient and reproducible. Containers on one VM, config
  generated from one source of truth, a one-command demo.
- Prove it against an attack, and show recovery. The demo blocks a pivot, detects
  it, and revokes the attacker live without downtime for others.

## Per-worklet upgrade

Phase 1
- W1 Perimeter: add the `$` fix to the Snort HOME_NET rules so they load, then
  demo a scan detected and dropped, with the pfSense log as evidence.
- W2 Segmentation: demo a host in the IoT VLAN blocked from Admin, with the VyOS
  drop log, and show the policy surviving a VLAN-hop attempt.
- W3 Remote access: done, the template for the rest.

Phase 2
- W4 SIEM: correlate two sources into one alert, for example a WireGuard
  denied_traffic event from W3 plus a failed SSH, and show the analyst workflow.
- W5 Vulnerability management: the before and after scan is already the
  attack-and-recovery story; add the measured remediation deadline being met.
- W6 IAM and MFA: demo a stolen password defeated by the second factor, and a
  real-time phishing relay as the acknowledged residual risk.
- W7 WAF: demo SQLi and XSS blocked, a legitimate request still served, and tuning
  out a false positive, which is the recovery half.

Phase 3
- W8 Memory forensics: recover a hidden process and show the anti-forensics
  limitation, the process visible only in psscan.
- W9 Disk forensics: recover a deleted file and prove the image was not altered
  with matching before and after hashes.
- W10 Network forensics: reconstruct the attacker timeline from a capture and
  carve a transferred file, hashed.

## Sequencing

Worklet 3 is the showcase for the next review. After it, the highest-leverage
upgrades are W4, because it consumes W3's alerts and ties the phases together, and
W7, because the attack-and-recovery demo is quick and visual. The forensics
worklets in Phase 3 then reconstruct an incident that the earlier worklets
defended against, which is the capstone in docs/program-narrative.md.
