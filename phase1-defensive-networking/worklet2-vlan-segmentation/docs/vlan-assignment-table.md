# VLAN Assignment Table

VLAN 10, Admin, Trust Level High, allowed to reach IoT for management only on port 22 and 443, denied to reach Guest
VLAN 20, IoT, Trust Level Low, denied to reach Admin, denied to reach Guest
VLAN 30, Guest, Trust Level Untrusted, denied to reach Admin, denied to reach IoT, internet only

## Threat Model

Lateral movement: a compromised IoT device cannot pivot to Admin assets.
Guest isolation: guest devices get internet-only access, no internal reachability.
Residual risk: VLAN hopping via double-tagging if trunk ports are misconfigured, mitigate by explicitly setting the native VLAN to an unused ID.
