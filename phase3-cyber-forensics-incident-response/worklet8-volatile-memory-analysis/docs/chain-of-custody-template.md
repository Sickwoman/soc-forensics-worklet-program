# Chain of Custody Log

Case number, evidence ID, for example MEM-001, description of the memory dump including hostname and tool used, and the SHA-256 hash once computed with sha256sum.

Log each action taken with date and time, the action performed such as collected, transferred, or analyzed, the person responsible, the location, and a signature.

Row 1: Collected
Row 2: Transferred to analysis workstation
Row 3: Analysis started
Row 4: Analysis completed

## Threat Model, Evidence Integrity

Tampering: The dump is altered after collection, by accident or on purpose. Hash it at collection, re-hash after every transfer, and record each hash in this log. Analyze a copy and keep the original read only.
Repudiation: Gaps in the log let anyone question who had the evidence and when. Every hand-off gets a row with time, person, and signature.
Anti-forensics: Rootkits unlink their process from the active process list. Compare windows.pslist with windows.psscan, which carves process structures from all of memory, or the Linux equivalents. A process that only appears in psscan is suspicious.
Acquisition footprint: The capture tool changes memory, and memory keeps changing while it is read. Run the tool from external media, record its process ID so it can be ruled out, and note the capture start and end times.
Information Disclosure: Memory dumps contain passwords, keys, and session tokens. Store them encrypted and never commit them to the repo.
Residual risk: Malware that detects the capture tool can exit or wipe itself first. Capturing from the hypervisor instead, with VBoxManage debugvm dumpvmcore, runs nothing inside the guest.
