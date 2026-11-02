# Section 10: Manage Security (8 Objectives = 8 Labs)

> **Official RHEL 10 Objectives in Section 10 (8 Objectives):**
> 1. Configure firewall settings using `firewall-cmd`/`firewalld`
> 2. Manage default file permissions
> 3. Configure key-based authentication for SSH
> 4. Set enforcing and permissive modes for SELinux
> 5. List and identify SELinux file and process context
> 6. Restore default file contexts
> 7. Manage SELinux port labels
> 8. Use boolean settings to modify system SELinux settings

---

## Lab 10.1 — Objective 1: Configure firewall settings using `firewall-cmd`/`firewalld`
**Task:**
1. Ensure `firewalld` is enabled and active.
2. Persistently open TCP port **`82/tcp`** and the **`nfs`** service in the default zone, and reload `firewalld`.

---

## Lab 10.2 — Objective 2: Manage default file permissions
**Task:**
1. Configure user **`labuser1`**'s `~/.bashrc` so their default **`umask`** is set to **`0027`** (new files get `0640` `rw-r-----`, new directories get `0750` `rwxr-x---`).
2. Switch to `labuser1` (`su - labuser1 -c ...`) and create `/tmp/s10_umask_file` and `/tmp/s10_umask_dir` to test the new default permissions.

---

## Lab 10.3 — Objective 3: Configure key-based authentication for SSH
**Task:**
1. Generate an Ed25519 SSH key pair for user **`labuser1`** (`~/.ssh/id_ed25519`) with no passphrase.
2. Authorize `labuser1`'s public key inside `/home/labuser1/.ssh/authorized_keys` with correct permissions (`700` on `.ssh`, `600` on `authorized_keys`) so `labuser1` can run `ssh -o BatchMode=yes labuser1@localhost whoami` without a password.

---

## Lab 10.4 — Objective 4: Set enforcing and permissive modes for SELinux
**Task:**
1. Switch SELinux to `Permissive` mode temporarily (`setenforce 0`), then switch it back to **`Enforcing`** mode (`setenforce 1`).
2. Ensure `/etc/selinux/config` has **`SELINUX=enforcing`** configured persistently across reboots.

---

## Lab 10.5 — Objective 5: List and identify SELinux file and process context
**Task:**
1. Save the SELinux file context of `/var/www/html` (`ls -dZ /var/www/html`) into `~/labs/s10/www_context.txt`.
2. Start `httpd` (or `sshd`) and save its SELinux process context (`ps -efZ | grep -E 'sshd|httpd'`) into `~/labs/s10/proc_context.txt`.

---

## Lab 10.6 — Objective 6: Restore default file contexts
**Task:**
1. Create a file `/var/www/html/index.html` containing `SELinux Context Restored` and intentionally mislabel it with `chcon -t user_home_t /var/www/html/index.html`.
2. Also create a custom web directory **`/custom_web`** containing `custom.html`, define a persistent SELinux fcontext rule labeling `/custom_web(/.*)?` as **`httpd_sys_content_t`** (`semanage fcontext`), and restore default file contexts on both `/var/www/html` and `/custom_web` using **`restorecon -Rv`**.

---

## Lab 10.7 — Objective 7: Manage SELinux port labels
**Task:**
1. Configure SELinux policy to allow `httpd` (`http_port_t`) to bind and listen on TCP port **`82`** (`semanage port -a -t http_port_t -p tcp 82`).
2. Configure `httpd` to listen on port `82` (`Listen 82` in `/etc/httpd/conf/httpd.conf`) and restart `httpd`.

---

## Lab 10.8 — Objective 8: Use boolean settings to modify system SELinux settings
**Task:**
1. Inspect the current state of the SELinux boolean **`httpd_enable_homedirs`** (`getsebool`).
2. Persistently enable **`httpd_enable_homedirs`** (`setsebool -P httpd_enable_homedirs on`) so it survives a system reboot.
