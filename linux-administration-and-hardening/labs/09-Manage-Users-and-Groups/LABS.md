# Section 9: Manage Users and Groups (4 Objectives = 4 Labs)

> **Official RHEL 10 Objectives in Section 9 (4 Objectives):**
> 1. Create, delete, and modify local user accounts
> 2. Change passwords and adjust password aging for local user accounts
> 3. Create, delete, and modify local groups and group memberships
> 4. Configure superuser access

---

## Lab 9.1 — Objective 1: Create, delete, and modify local user accounts
**Task:**
1. Create a user **`s9_emma`** with UID **`4200`**, comment **`Emma Engineer`**, and login shell **`/bin/bash`**.
2. Create a service user **`s9_bot`** with shell **`/sbin/nologin`** and no home directory (`-M`).
3. Modify **`s9_emma`**'s comment to **`Emma Senior Engineer`** (`usermod -c`).
4. Create a temporary user **`s9_temp`** and then completely delete **`s9_temp`** along with their home directory (`userdel -r`).

---

## Lab 9.2 — Objective 2: Change passwords and adjust password aging for local user accounts
**Task:**
1. Set the password for **`s9_emma`** to **`atenorth`**.
2. Adjust password aging for **`s9_emma`** (`chage`) so that:
   - Minimum days between password changes is **`3`** (`-m 3`)
   - Maximum days password is valid is **`60`** (`-M 60`)
   - Warning period before expiration is **`10`** days (`-W 10`)
   - Account expires on **`2027-06-30`** (`-E 2027-06-30`)
3. Set `PASS_MAX_DAYS 30` in `/etc/login.defs` for all newly created users.

---

## Lab 9.3 — Objective 3: Create, delete, and modify local groups and group memberships
**Task:**
1. Create a group **`s9_devs`** with GID **`42000`** and a group **`s9_obsolete`** with GID **`42001`**.
2. Rename group `s9_obsolete` to `s9_temp_grp` (`groupmod -n`) and then delete `s9_temp_grp` (`groupdel`).
3. Add user **`s9_emma`** to supplementary group **`s9_devs`** (`usermod -aG`).

---

## Lab 9.4 — Objective 4: Configure superuser access
**Task:**
1. Create a sudoers drop-in file at **`/etc/sudoers.d/s9_devs`** (`chmod 0440`) that allows all members of group **`s9_devs`** (`%s9_devs`) and user **`s9_emma`** to run any command as any user **without a password** (`NOPASSWD: ALL`).
2. Verify syntax with `visudo -c` and test running `sudo whoami` as `s9_emma`.
