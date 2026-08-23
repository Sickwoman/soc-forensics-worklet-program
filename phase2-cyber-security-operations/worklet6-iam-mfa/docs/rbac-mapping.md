# RBAC Mapping

Role Administrator, Group admins, Permissions full sudo access and reachability to all VLANs, MFA required Yes.
Role Security Analyst, Group soc-team, Permissions read-only access to the SIEM, no sudo, MFA required Yes.
Role Standard User, Group users, Permissions own workstation only, MFA required Yes.
Role Guest, Group guests, Permissions internet only, no internal systems, MFA required No, isolated network instead.
