# SOC, Forensics & Networking Worklet Program

## Context
Integrated worklet program covering defensive networking, security operations,
and digital forensics. Each worklet is delivered as Documentation, Prototyping,
and a Functioning Model, evaluated by a faculty mentor.

## Target Audience
Engineering and Computer Science students, faculty mentor required for supervision.

## Phase 1 - Defensive Networking, Weeks 1 to 4
- Worklet 1: Hardened Perimeter Gateway, pfSense with Snort IDS
- Worklet 2: VLAN Segmentation and Zero Trust, VyOS Layer 3 switch
- Worklet 3: Secure Remote Connectivity, WireGuard VPN

## Phase 2 - Cyber Security Operations, Weeks 5 to 8
- Worklet 4: SOC Visibility, Wazuh or ELK SIEM
- Worklet 5: Vulnerability Management, OpenVAS scan and remediation
- Worklet 6: Identity and Access Management, FreeIPA with MFA
- Worklet 7: Web Application Defense, Nginx with ModSecurity WAF

## Phase 3 - Cyber Forensics and Incident Response, Weeks 9 to 12
- Worklet 8: Volatile Memory Analysis, Volatility 3
- Worklet 9: Dead-Box Disk Forensics, Autopsy
- Worklet 10: Network Forensics, Wireshark and PCAP analysis

## Lab Setup
- Kali Linux as the primary attacker and analysis workstation
- VirtualBox or VMware for virtualization
- Host-only and internal networks configured for isolated lab traffic
- Planned VMs: pfSense, VyOS, Ubuntu Server x2, Metasploitable2 or 3, Windows 10 client

## Evaluation
Each worklet is graded by the faculty mentor on three criteria, Documentation,
Prototyping, and Functioning Model, each on a scale of Developing, Proficient,
or Advanced. See docs/rubric.md for details.

## Repo Layout
Each worklet folder contains a README with objective and build steps, a docs
folder with required documentation deliverables, and a config or scripts folder
with working configs or helper scripts.
