# Worklet 8: Volatile Memory Analysis

Objective: Analyze live memory artifacts to find hidden processes and command history.

## Build Steps

1. On the target VM, Windows or Linux, simulate compromise by running a hidden or renamed process.
2. Capture memory. On Windows, use DumpIt to produce a raw or dmp file. On Linux, use LiME as a kernel module, inserted with a path and format parameter to produce a lime file.
3. Copy the dump to your Kali analysis box, and log the transfer in docs/chain-of-custody-template.md.
4. Run scripts/volatility-analysis.sh against the dump.
5. Identify the hidden process and extract the command line history.

## Evidence to capture

- Chain of custody log, filled in completely
- Volatility output identifying the hidden or suspicious process
- Extracted command history or process tree

## Lessons Learned / Limitations

Fill in after testing.
