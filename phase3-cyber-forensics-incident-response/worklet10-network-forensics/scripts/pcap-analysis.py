#!/usr/bin/env python3
"""
Quick first-pass PCAP triage.
Usage: python3 pcap-analysis.py capture.pcap
Requires: pip install scapy --break-system-packages
"""
import sys
from collections import Counter
from scapy.all import rdpcap, IP, TCP

def main(path):
    packets = rdpcap(path)
    talkers = Counter()
    ports = Counter()
    suspicious_ports = {21, 23, 445, 3389, 4444, 1337}

    for pkt in packets:
        if IP in pkt:
            talkers[pkt[IP].src] += 1
        if TCP in pkt:
            ports[pkt[TCP].dport] += 1

    print("Total packets:", len(packets))
    print("")
    print("Top 10 talkers by source IP:")
    for ip, count in talkers.most_common(10):
        print(" ", ip, ":", count, "packets")

    print("")
    print("Top destination ports:")
    for port, count in ports.most_common(10):
        flag = "  SUSPICIOUS" if port in suspicious_ports else ""
        print(" ", port, ":", count, "packets", flag)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 pcap-analysis.py capture.pcap")
        sys.exit(1)
    main(sys.argv[1])
