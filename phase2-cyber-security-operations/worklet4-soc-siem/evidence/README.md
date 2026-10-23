# Worklet 4 Evidence

Runtime evidence from the lightweight Wazuh manager (Docker, no dashboard) run on
WSL2 on an 8 GB Windows machine. Detection was shown with wazuh-logtest, which
runs the same decoders and rules the live pipeline uses.

- 00-environment.txt — the host and Wazuh version.
- 10-ssh-bruteforce-logtest.txt — ten failed SSH logins from one source IP; Wazuh
  fires rule 5710 (level 5) per attempt and escalates to rule 5712 (level 10,
  brute force) on the eighth, with MITRE T1110 mapping.
- 11-zerotrust-bridge-logtest.txt — a Worklet 3 wg-monitor denied_traffic event
  decoded as JSON and raised to rule 100101 (level 12) by the bridge rules in
  config/wazuh-local-rules.xml.

Reproduce with:
  bash scripts/wazuh-lab.sh up
  bash scripts/wazuh-lab.sh rules
  bash scripts/wazuh-lab.sh test

No secrets are included.
