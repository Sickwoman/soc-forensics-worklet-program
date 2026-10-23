# Forensic Integrity Log

Source device, for example /dev/sdb or a VM virtual disk.
Image file, evidence.dd.
Acquisition tool, dd or FTK Imager.
Acquisition date and time.
MD5 hash of the source.
SHA-256 hash of the source.
MD5 hash of the image after acquisition.
SHA-256 hash of the image after acquisition.
Match confirmed, yes or no.
Analyst name.

## Threat Model, Evidence Integrity

Tampering: Writing to the source disk during acquisition, for example by mounting it, which replays the journal and updates access times. Do not mount the source. If it must be mounted, use read only with the noload option, and use a hardware write blocker for physical disks.
Tampering: The image is changed after acquisition. Re-compute the hashes above when analysis ends, they must still match.
Bad sectors: dd with conv=noerror,sync fills unreadable blocks with zeros, so the image hash will not match the source. Record the dd error output and the number of failed blocks in this log.
Anti-forensics: Secure deletion overwrites file content, so only metadata may be recoverable. Timestomping changes file times, so compare the NTFS $STANDARD_INFORMATION and $FILE_NAME timestamps, a mismatch suggests tampering.
Encryption: A BitLocker or LUKS volume yields only ciphertext without the key. Note the encryption here, and capture memory first per Worklet 8, since the key may be in RAM.
Information Disclosure: The image holds everything on the disk. Store it encrypted and never commit it to the repo.
Residual risk: Data held only in cloud storage, or already overwritten, is out of reach of disk forensics.
