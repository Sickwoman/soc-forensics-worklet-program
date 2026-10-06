# Worklet 10: Network Forensics, Packet Analysis

Objective: Reconstruct an attack from captured network traffic.

## Lab Topology

  Kali attacker VM, also capturing with tcpdump on its Host-only interface
    attack traffic to and from the Metasploitable target on 10.10.10.0/24
      capture.pcap hashed with sha256sum, then analyzed with scripts/pcap-analysis.py and Wireshark

## Build Steps

1. On Kali, start a capture during a simulated attack using tcpdump, writing to capture.pcap.
2. Run an attack against the target, for example a Metasploitable FTP exploit or an unencrypted file transfer to carve later.
3. Stop the capture and open it in Wireshark.
4. Run scripts/pcap-analysis.py for a first pass automated summary, including top talkers and suspicious ports.
5. Identify the attacker source IP, the protocol used, and carve any transferred file out of the stream using Wireshark's Follow TCP Stream and Export Objects features.
6. Write up the timeline in docs/incident-timeline-report-template.md.

## Evidence to capture

- Attacker IP address and timestamp of the first malicious packet
- Carved file, for example an exfiltrated document, along with its hash
- Completed incident timeline report

## Lessons Learned / Limitations

Fill in after testing.
