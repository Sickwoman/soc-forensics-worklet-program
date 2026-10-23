# Evidence Guide

How to store the evidence listed in docs/rubric.md, so the faculty mentor can check each worklet in one place.

## Where Evidence Goes

Each worklet gets an evidence folder next to its docs folder, for example phase1-defensive-networking/worklet1-hardened-perimeter-gateway/evidence.
The Evidence to capture list in each worklet README says what goes in it.

## File Naming

Start each file name with the build step number, then before or after, then a short description, for example 06-before-nmap-syn-scan.txt or 06-after-snort-alert.png.
Prefer text files for logs and command output, so they can be searched and compared. Use a screenshot when the evidence is a GUI, such as a dashboard.
Start every log excerpt with a line giving the host, the file it came from, and the time range in UTC.

## Before and After Pairs

Each defense needs a pair, the attack working before the control is applied, and failing or being detected after it.
Run the same command both times, so the only difference between the two files is the control.

## What Never Goes in the Repo

Private keys, WireGuard keys, TOTP secrets, and real passwords. Replace them with the word REDACTED before committing.
Memory dumps, disk images, and full packet captures. They are large and contain credentials, so commit their SHA-256 hashes and the excerpts you used instead. The .gitignore at the repo root blocks the common file types.
Anything collected from a host outside the lab.
