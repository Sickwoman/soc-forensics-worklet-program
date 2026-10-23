# Program Narrative and Capstone

The ten worklets are easier to present, and far more convincing, as one defended
organisation than as ten separate labs. This document gives that frame and a
capstone exercise that threads all of them.

## The organisation

Northwind Labs is a small fictional engineering company, modelled entirely in the
lab VMs. It has a perimeter, internal segments for Admin, IoT, and Guest, a few
internal services, remote staff, a SOC of one analyst, and the bad luck to be
targeted. Each worklet is one layer of Northwind's defence:

- Perimeter and detection, W1 pfSense and Snort.
- Segmentation, W2 VLANs and zero-trust routing.
- Remote access, W3 Zero Trust WireGuard.
- Visibility, W4 the SIEM that watches all of it.
- Hygiene, W5 vulnerability management.
- Identity, W6 IAM and MFA.
- Application defence, W7 the WAF.
- Incident response, W8 to W10 memory, disk, and network forensics.

## The golden thread, one incident across the program

The capstone is a single intrusion that each worklet either defends against or
helps reconstruct. It can be run end to end for a final review, or told as the
story that connects the individual demos.

1. Recon. An attacker scans Northwind's perimeter. W1 Snort detects the scan and
   pfSense drops the noisy parts. First evidence: the IDS alert.
2. Remote access attempt. The attacker phishes a contractor's WireGuard laptop,
   mallory, and gets on the VPN. W3 contains it: mallory's key reaches only the
   web app, and when the laptop probes toward the database the Zero Trust firewall
   drops it and wg-monitor raises an alert. Evidence: the denied_traffic alert.
3. Identity holds. The attacker tries the stolen credentials against an internal
   SSH service. W6 MFA stops the password-only login. Evidence: the auth failure.
4. Detection and correlation. W4 the SIEM correlates the WireGuard denied_traffic
   event with the SSH failures into one high-severity incident, and the analyst
   starts the response. Evidence: the correlated alert.
5. Web attack blocked. Pivoting to the public web app, the attacker sends SQL
   injection. W7 the WAF returns 403 and logs the rule that fired, while real
   traffic is still served. Evidence: the 403 and the audit log line.
6. Containment. The analyst revokes mallory's access live, W3, and the VLAN policy
   from W2 confirms the Guest and IoT segments were never reachable from her
   foothold. Evidence: wg show before and after, and the VyOS drop log.
7. Forensics. After containment, the team reconstructs what happened: W8 finds the
   attacker's process in a memory capture, W9 recovers a deleted staging file from
   a disk image with integrity proven by hashes, and W10 rebuilds the timeline and
   carves the transferred file from the packet capture. Evidence: the chain of
   custody, the recovered artefacts, and the incident timeline.

## Why this impresses

It turns a checklist of tools into a story a defender can tell: an attacker tried,
each layer did its job, the one foothold was contained in seconds, and the team
reconstructed the whole event afterward. It also shows the worklets were designed
to interlock, W3 feeds W4, W4 drives the response, Phase 3 reconstructs it, which
is exactly the systems thinking the Advanced rubric is looking for.

## Running the capstone

Each numbered step maps to that worklet's existing demo and evidence, so the
capstone is assembled from work already done, not built from scratch. Start with
the W3 demo, which already shows steps 2 and 6 live, and add the other steps as
each worklet reaches Advanced per docs/roadmap.md.
