# Worklet 6: Identity and Access Management, IAM

Objective: Secure authentication using multi-factor authentication, password plus TOTP.

## Lab Topology

  Kali or Windows client, SSH over TCP 22
    connects to Ubuntu Server MFA host
      sshd hands keyboard-interactive login to PAM, password via pam_unix, then TOTP via pam_google_authenticator
      login allowed only for the groups admins, soc-team, and users

## Build Steps

1. Set up a lightweight MFA demo using libpam-google-authenticator on an Ubuntu Server VM, or use FreeIPA for a fuller IAM deployment if time allows.
2. Create user accounts and groups per docs/rbac-mapping.md by running sudo bash scripts/provision-rbac-users.sh. It also adds your own admin account to the admins group.
3. Install the TOTP package with apt install libpam-google-authenticator, then enroll each user per docs/authentication-policy.md, for example sudo -u alice -H google-authenticator -t -d -f -r 3 -R 30 -w 3, and scan the QR code into an authenticator app. Enroll your own admin account too.
4. Edit /etc/pam.d/sshd and add the line from config/pam-sshd-mfa.conf directly below @include common-auth.
5. Copy config/sshd-mfa.conf to /etc/ssh/sshd_config.d/10-mfa.conf. On Ubuntu 22.04 or newer, adding ChallengeResponseAuthentication yes to the end of sshd_config has no effect, because the earlier KbdInteractiveAuthentication no line wins, so use the drop-in file.
6. Run sudo sshd -t to check the config, then restart the ssh service while keeping your current session open.
7. SSH into the host and confirm both the password and the six digit verification code are required.
8. Confirm guest1 is refused, and that bob can read /var/log/auth.log but cannot use sudo.

## Evidence to capture

- SSH login prompt showing both the password step and the verification code step
- A failed login attempt when the TOTP code is wrong or missing
- RBAC group membership listing for the test users, printed at the end of provision-rbac-users.sh
- The auth.log lines for the refused guest1 login and the failed TOTP attempt

## Lessons Learned / Limitations

Fill in after testing.
