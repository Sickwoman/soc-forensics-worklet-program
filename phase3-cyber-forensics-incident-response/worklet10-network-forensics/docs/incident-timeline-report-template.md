# Incident Timeline Report

Record each event with the time in UTC, the source IP, the destination IP, the event description, and the packet number as evidence.

Row 1: Reconnaissance or port scan
Row 2: Initial exploit attempt
Row 3: Successful compromise
Row 4: Data exfiltration or file transfer

## Summary

Attacker IP address.
Entry vector used.
Files or data impacted.
Recommended remediation steps.

## Threat Model, Evidence Integrity

Tampering: The capture file is edited after the fact. Hash capture.pcap with sha256sum as soon as the capture stops, and work on a copy.
Incomplete evidence: tcpdump drops packets when it cannot keep up, and prints a packets dropped by kernel count when it stops. Record that count here, and always capture to a file rather than the screen.
Repudiation: Timestamps from a capture host with a wrong clock cannot be lined up with SIEM or firewall logs. Sync the capture host with NTP and record every time in UTC.
Spoofing: Source IPs can be forged, and NAT hides the real host. Confirm the attacker IP with a completed TCP handshake, which a forged source cannot finish, and with the firewall logs from Worklet 1.
Encrypted traffic: TLS hides payloads, so file carving fails. Fall back on metadata, such as the TLS server name, certificate, timing, and volume.
Information Disclosure: Captures contain credentials sent in clear text, for example FTP and Telnet logins. Store them encrypted and never commit real captures to the repo.
Residual risk: Traffic that never crosses the capture point, such as host to host traffic on another VLAN, is not seen, so choose the capture point with the topology in mind.
