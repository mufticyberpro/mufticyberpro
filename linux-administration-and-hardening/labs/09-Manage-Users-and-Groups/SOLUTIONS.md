# Section 9: Manage Users and Groups — Solutions & Verification (4 Labs)

---

## Lab 9.1 — Create, delete, and modify local user accounts

### Solution
```bash
userdel -r s9_emma 2>/dev/null || true
userdel -r s9_bot  2>/dev/null || true

useradd -u 4200 -c "Emma Engineer" -s /bin/bash s9_emma
useradd -M -s /sbin/nologin s9_bot

usermod -c "Emma Senior Engineer" s9_emma

useradd -m s9_temp
userdel -r s9_temp
```

### Verify
```bash
id -u s9_emma                                            # expect 4200
getent passwd s9_emma | grep -c 'Emma Senior Engineer'   # expect 1
getent passwd s9_bot  | grep -c '/sbin/nologin'          # expect 1
id s9_temp 2>/dev/null                                   # expect nothing (deleted)
```

**Explanation:** `useradd` creates local accounts, `usermod` modifies existing account attributes, and `userdel -r` deletes an account along with its home directory and mail spool.

---

## Lab 9.2 — Change passwords and adjust password aging for local user accounts

### Solution
```bash
echo "s9_emma:atenorth" | chpasswd
chage -m 3 -M 60 -W 10 -E 2027-06-30 s9_emma
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   30/' /etc/login.defs
```

### Verify
```bash
chage -l s9_emma | awk -F': ' '/Maximum number of days/{print $2}'  # expect 60
chage -l s9_emma | awk -F': ' '/Minimum number of days/{print $2}'  # expect 3
awk '/^PASS_MAX_DAYS/{print $2}' /etc/login.defs                    # expect 30
```

**Explanation:** `chpasswd` (or `passwd --stdin`) sets user passwords non-interactively, `chage` adjusts password aging for existing users, and `/etc/login.defs` sets defaults for future users.

---

## Lab 9.3 — Create, delete, and modify local groups and group memberships

### Solution
```bash
groupdel s9_devs 2>/dev/null || true
groupadd -g 42000 s9_devs
groupadd -g 42001 s9_obsolete

groupmod -n s9_temp_grp s9_obsolete
groupdel s9_temp_grp

usermod -aG s9_devs s9_emma
```

### Verify
```bash
getent group s9_devs | cut -d: -f3           # expect 42000
id -nG s9_emma | grep -cw 's9_devs'          # expect 1
getent group s9_temp_grp 2>/dev/null         # expect nothing (deleted)
```

**Explanation:** `groupadd -g` creates a group with a specific GID, `groupmod -n` renames a group, `groupdel` removes it, and `usermod -aG` appends a user to a supplementary group.

---

## Lab 9.4 — Configure superuser access

### Solution
```bash
cat << 'EOF' > /etc/sudoers.d/s9_devs
%s9_devs  ALL=(ALL)  NOPASSWD: ALL
s9_emma   ALL=(ALL)  NOPASSWD: ALL
EOF

chmod 0440 /etc/sudoers.d/s9_devs
visudo -c
```

### Verify
```bash
visudo -cf /etc/sudoers.d/s9_devs | grep -c 'parsed OK'  # expect 1
su - s9_emma -c "sudo whoami"                            # expect root
```

**Explanation:** Drop-in files in `/etc/sudoers.d/` grant superuser privileges (`%group` for groups, `username` for individual users), and `NOPASSWD: ALL` allows execution without a password prompt.
