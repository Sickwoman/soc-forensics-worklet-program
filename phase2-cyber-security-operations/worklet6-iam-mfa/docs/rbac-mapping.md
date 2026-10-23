# RBAC Mapping

Role Administrator, Group admins, Permissions full sudo access and reachability to all VLANs, MFA required Yes.
Role Security Analyst, Group soc-team, Permissions read-only access to the SIEM, no sudo, MFA required Yes.
Role Standard User, Group users, Permissions own workstation only, MFA required Yes.
Role Guest, Group guests, Permissions internet only, no internal systems, MFA required No, isolated network instead.

## Enforcement on the Ubuntu MFA Host

Groups and test users, alice for admins, bob for soc-team, carol for users, guest1 for guests, are created by scripts/provision-rbac-users.sh.
Administrator sudo comes from /etc/sudoers.d/admins, which grants the admins group full sudo.
Security Analyst read-only access on this host comes from the adm group, which can read /var/log but cannot change anything.
SSH login is limited to admins, soc-team, and users by AllowGroups in config/sshd-mfa.conf, so guest1 is refused even if someone later gives it a password.
Guests also get /usr/sbin/nologin as their shell, so there is no interactive session even at the console.
