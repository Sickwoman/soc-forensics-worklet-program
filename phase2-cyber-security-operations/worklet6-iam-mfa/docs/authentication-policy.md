# Authentication and MFA Policy

## Factors

First factor, the account password, checked by pam_unix through common-auth.
Second factor, a six digit TOTP code from an authenticator app, checked by pam_google_authenticator.
Both factors are required for every role that can log in, see docs/rbac-mapping.md. Guests have no login, they are isolated on the Guest VLAN instead.

## Enrollment

Enrollment is admin-assisted, at the console, never over an unprotected channel.
The admin runs google-authenticator as the user, with time-based codes, reuse disallowed, a rate limit of 3 attempts per 30 seconds, and a window of 3 codes, so the secret file is created in the user's own home directory.
The user scans the QR code into their own authenticator app and confirms one code before the session ends.
The secret file ~/.google_authenticator must stay owned by the user at permission 400, or 600 at most, pam_google_authenticator refuses to use it otherwise.

## Recovery

google-authenticator prints five single-use emergency scratch codes at enrollment. The user stores them offline, never on the same phone as the authenticator app.
Lost device, the admin deletes the user's ~/.google_authenticator file and re-enrolls them at the console after verifying their identity.
Each used scratch code is crossed off. When fewer than two remain, the user is re-enrolled.

## Lockout and Rate Limiting

sshd allows 3 authentication attempts per connection, MaxAuthTries in config/sshd-mfa.conf.
pam_google_authenticator rate limits to 3 code attempts per 30 seconds per user, set at enrollment.
Failed logins are forwarded to the Wazuh SIEM, see Worklet 4, where a burst raises a brute force alert.

## Account Lifecycle

Joiner, the account is created with scripts/provision-rbac-users.sh in the group for its role, then enrolled for TOTP.
Mover, the user is removed from the old role group before being added to the new one, never both at once.
Leaver, the account is locked with usermod --lock --expiredate 1, which also blocks SSH key logins, and its shell set to /usr/sbin/nologin on the same day. The home directory, including the TOTP secret, is archived and then removed after 30 days.
Group membership is reviewed every 90 days against docs/rbac-mapping.md.

## Threat Model, STRIDE-lite

Spoofing: Stolen or guessed passwords, from credential stuffing or brute force. Mitigated by the second factor, MaxAuthTries, and the TOTP rate limit.
Spoofing: Real-time phishing, where an attacker relays a valid TOTP code within its 30 second window. TOTP does not stop this. Mitigate with SSH keys plus TOTP for admins, the publickey,keyboard-interactive option in config/sshd-mfa.conf.
Tampering: An attacker with root on the host can read every ~/.google_authenticator secret and clone the second factor. Mitigated by limiting sudo to the admins group and alerting on reads of those files.
Repudiation: Shared accounts hide who logged in. Every user has a named account, and root SSH login is disabled.
Elevation of Privilege: A standard user gaining sudo. Only the admins group is in sudoers, and the sudoers file is validated with visudo before install.
Denial of Service: Rate limiting can lock out a legitimate user under attack. Emergency scratch codes and console access are the recovery path.
Residual risk: TOTP secrets are shared secrets, unlike FIDO2 hardware keys, so a compromised server or phone leaks them. FIDO2 with sk-ssh-ed25519 keys is the stronger next step.
