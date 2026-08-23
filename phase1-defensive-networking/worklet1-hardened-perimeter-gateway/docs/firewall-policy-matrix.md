# Firewall Policy Matrix

Rule 1: Source Any WAN, Destination pfSense WAN IP, Port TCP 443, Action Allow, Notes Admin GUI, restrict to mgmt IP in production
Rule 2: Source LAN net, Destination Any, Port Any, Action Allow, Notes Default outbound
Rule 3: Source Any WAN, Destination LAN net, Port Any, Action Deny, Notes Default deny inbound
Rule 4: Source WAN, Destination Internal Web Server, Port TCP 80 and 443, Action Allow, Notes Published service, WAF in front, see Worklet 7
Rule 5: Source Any, Destination Any, Port ICMP, Action Rate-limit, Notes Prevent ping flood recon
Rule 6: Source Any WAN, Destination Any, Port Snort preprocessor, Action IDS or Block, Notes Emerging Threats plus custom rules

## Threat Model, STRIDE-lite

Spoofing: WAN-side spoofed source IPs, mitigated by RFC1918 and bogon filtering.
Info Disclosure: Port scans, detected by Snort portscan preprocessor.
Denial of Service: SYN floods, mitigated by pfSense state table limits and rate limiting rules.
Residual risk: Zero-day exploits against pfSense or Snort itself, mitigate with prompt patching.
