# Worklet 2: VLAN Segmentation and Zero Trust

Objective: Isolate internal traffic, Admin, IoT, and Guest, to prevent lateral movement.

## Lab Topology

  VyOS Router or Switch VM, one NIC on a VirtualBox internal network named trunk-net
    VLAN 10, Admin, subnet 10.10.10.0/24
    VLAN 20, IoT, subnet 10.10.20.0/24
    VLAN 30, Guest, subnet 10.10.30.0/24

## Build Steps

1. Create a VyOS VM with one NIC attached to the VirtualBox internal network trunk-net.
2. Configure VLAN sub-interfaces per config/vyos-vlan-config.txt.
3. Attach three test VMs, or a multi-NIC Kali VM, tagged into VLAN 10, VLAN 20, and VLAN 30.
4. Apply firewall zone policy, deny IoT to Admin, deny Guest to Admin and IoT.
5. From an IoT VLAN host, attempt to reach an Admin VLAN host, confirm it fails.
6. From the Admin VLAN, confirm reachability to IoT or Guest per policy.

## Evidence to capture

- Ping or SSH attempt from IoT VLAN to Admin VLAN failing
- VyOS firewall log showing the drop
- Output of show interfaces confirming VLAN sub-interfaces are up

## Lessons Learned / Limitations

Fill in after testing.
