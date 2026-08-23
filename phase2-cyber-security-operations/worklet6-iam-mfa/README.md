# Worklet 6: Identity and Access Management, IAM

Objective: Secure authentication using multi-factor authentication, password plus TOTP.

## Build Steps

1. Set up a lightweight MFA demo using libpam-google-authenticator on an Ubuntu Server VM, or use FreeIPA for a fuller IAM deployment if time allows.
2. Create user accounts and groups per docs/rbac-mapping.md.
3. Install the TOTP package with apt install libpam-google-authenticator, then run google-authenticator as the test user and scan the QR code into an authenticator app.
4. Edit /etc/pam.d/sshd and add a line requiring pam_google_authenticator.so.
5. Set ChallengeResponseAuthentication to yes in /etc/ssh/sshd_config, then restart the ssh service.
6. SSH into the host and confirm both the password and the six digit verification code are required.

## Evidence to capture

- SSH login prompt showing both the password step and the verification code step
- A failed login attempt when the TOTP code is wrong or missing
- RBAC group membership listing for the test users

## Lessons Learned / Limitations

Fill in after testing.
