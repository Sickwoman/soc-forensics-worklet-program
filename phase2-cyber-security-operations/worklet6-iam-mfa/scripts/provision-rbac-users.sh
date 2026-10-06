#!/usr/bin/env bash
# Create the groups and one test user per role from docs/rbac-mapping.md on the Ubuntu MFA host.
# Usage: sudo bash provision-rbac-users.sh
# Safe to re-run, existing groups and users are left alone.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root, for example with sudo"
    exit 1
fi

# group:test-user pairs, one per role in docs/rbac-mapping.md
ROLES="admins:alice soc-team:bob users:carol guests:guest1"

for pair in $ROLES; do
    group="${pair%%:*}"
    user="${pair##*:}"

    getent group "$group" >/dev/null || groupadd "$group"

    if id "$user" >/dev/null 2>&1; then
        echo "User $user already exists, skipping"
        continue
    fi

    # Guests get no interactive shell, matching internet only with no internal systems
    # Analysts get read-only log access on this host through the adm group, but no sudo
    shell=/bin/bash
    groups="$group"
    [ "$group" = guests ] && shell=/usr/sbin/nologin
    [ "$group" = soc-team ] && groups="$group,adm"
    useradd -m -s "$shell" -G "$groups" "$user"

    if [ "$group" != guests ]; then
        echo "Set a password for $user, role group $group"
        until passwd "$user"; do echo "Try again"; done
    fi
done

# The account running this script is the lab admin, add it to admins so AllowGroups in sshd-mfa.conf does not lock it out
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
    usermod -aG admins "$SUDO_USER"
    echo "Added $SUDO_USER to admins"
fi

# Admins get full sudo, validated with visudo before it is installed
tmp=$(mktemp)
echo "%admins ALL=(ALL:ALL) ALL" > "$tmp"
visudo -cf "$tmp"
install -m 440 -o root -g root "$tmp" /etc/sudoers.d/admins
rm -f "$tmp"

echo ""
echo "Group membership, save this as RBAC evidence:"
getent group admins soc-team users guests adm
echo ""
echo "Next, enroll each user who can log in, for example:"
echo "  sudo -u alice -H google-authenticator -t -d -f -r 3 -R 30 -w 3"
