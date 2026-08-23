# Worklet 1: Hardened Perimeter Gateway

Objective: Secure the front door of the network with pfSense and Snort IDS.

## Lab Topology

  Internet, WAN, NAT'd VirtualBox adapter
      |
  pfSense VM, WAN interface em0 on NAT, LAN interface em1 on Host-only 10.10.10.1/24
      |
  Kali attacker VM and Target VM, both on Host-only 10.10.10.0/24

## Build Steps

1. Create pfSense VM: 2 NICs, WAN set to NAT, LAN set to Host-only vboxnet0, 2GB RAM, 20GB disk.
2. Install pfSense, assign WAN and LAN interfaces at the console.
3. From the LAN GUI, enable the Snort package under System, Package Manager.
4. Configure Snort on the WAN interface with the Emerging Threats ruleset.
5. Add firewall rules per docs/firewall-policy-matrix.md.
6. From Kali, run a SYN scan against the pfSense LAN IP as root, confirm Snort alerts and pfSense blocks or logs it.

## Evidence to capture

- Snort alert log showing the scan detected
- pfSense firewall log showing blocked packets
- Screenshot of the Snort dashboard

## Lessons Learned / Limitations

Fill in after testing.
