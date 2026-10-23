# Worklet 9: Dead-Box Disk Forensics

Objective: Recover deleted files and reconstruct browser activity timeline.

## Evidence Flow

  Target VM, powered off
    its virtual disk attached to the Kali analysis VM as a second disk, not mounted, for example /dev/sdb
      imaged with dd to evidence.dd, source and image hashed with scripts/verify-image-integrity.sh
        evidence.dd added to an Autopsy case, hashes re-checked when analysis ends

## Build Steps

1. Create a disk image of the target VM's disk using dd, reading from the source device and writing to evidence.dd, with a reasonable block size and error handling flags.
2. Compute and log the hash of the image using sha256sum, and record it in docs/forensic-integrity-log-template.md.
3. Open the image as a new case in Autopsy, adding evidence.dd as a disk image data source.
4. Run the Recent Activity and Deleted Files ingest modules.
5. Recover a deliberately deleted file and verify its contents match the original.
6. Reconstruct the browser history timeline, including visited URLs and download history.

## Evidence to capture

- Forensic integrity log with before and after hashes confirming the image was not altered
- Screenshot of the recovered deleted file in Autopsy
- Browser timeline export from Autopsy

## Lessons Learned / Limitations

Fill in after testing.
