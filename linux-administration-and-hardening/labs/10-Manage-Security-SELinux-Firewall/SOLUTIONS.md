# Section 10: Manage Security — Solutions & Verification (8 Labs)

---

## Lab 10.1 — Configure firewall settings using `firewall-cmd`/`firewalld`

### Solution
```bash
systemctl enable --now firewalld
firewall-cmd --permanent --add-port=82/tcp
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
```

### Verify
```bash
firewall-cmd --list-ports | grep -c '82/tcp'             # expect 1
firewall-cmd --list-services | grep -cw 'nfs'            # expect 1
```

**Explanation:** `firewall-cmd --permanent` saves rules across reboots and `firewall-cmd --reload` activates them immediately.

---

## Lab 10.2 — Manage default file permissions

### Solution
```bash
id labuser1 &>/dev/null || useradd -m -s /bin/bash labuser1
sed -i '/^umask /d' /home/labuser1/.bashrc
echo "umask 0027" >> /home/labuser1/.bashrc

rm -rf /tmp/s10_umask_file /tmp/s10_umask_dir
su - labuser1 -c "touch /tmp/s10_umask_file && mkdir /tmp/s10_umask_dir"
```

### Verify
```bash
stat -c %a /tmp/s10_umask_file               # expect 640
stat -c %a /tmp/s10_umask_dir                # expect 750
```

**Explanation:** `umask 0027` masks out group write (`2`) and all permissions for others (`7`), producing `0640` (`0666 - 0027`) for new files and `0750` (`0777 - 0027`) for new directories.

---

## Lab 10.3 — Configure key-based authentication for SSH

### Solution
```bash
su - labuser1 -c '
  mkdir -p ~/.ssh && chmod 700 ~/.ssh
  rm -f ~/.ssh/id_ed25519*
  ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
  cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
'
```

### Verify
```bash
su - labuser1 -c "ssh -o StrictHostKeyChecking=no -o BatchMode=yes labuser1@localhost whoami"  # expect labuser1
```

**Explanation:** SSH requires `~/.ssh` to be `0700` and `~/.ssh/authorized_keys` to be `0600` owned by the user; otherwise `sshd` refuses key-based authentication.

---

## Lab 10.4 — Set enforcing and permissive modes for SELinux

### Solution
```bash
setenforce 0
setenforce 1
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
```

### Verify
```bash
getenforce                                   # expect Enforcing
grep '^SELINUX=enforcing' /etc/selinux/config # expect SELINUX=enforcing
```

**Explanation:** `setenforce 1` switches SELinux to Enforcing immediately, while `SELINUX=enforcing` in `/etc/selinux/config` persists across reboots.

---

## Lab 10.5 — List and identify SELinux file and process context

### Solution
```bash
mkdir -p ~/labs/s10 /var/www/html
ls -dZ /var/www/html > ~/labs/s10/www_context.txt
ps -efZ | grep -E 'sshd|httpd' > ~/labs/s10/proc_context.txt
```

### Verify
```bash
grep -c 'httpd_sys_content_t' ~/labs/s10/www_context.txt # expect 1
grep -c 'sshd_t' ~/labs/s10/proc_context.txt             # expect >= 1
```

**Explanation:** The `-Z` flag works across `ls -Z`, `ps -Z`, `id -Z`, and `ss -Z` to inspect SELinux user, role, type (`_t`), and MLS/MCS level.

---

## Lab 10.6 — Restore default file contexts

### Solution
```bash
dnf install -y httpd policycoreutils-python-utils &>/dev/null || true
mkdir -p /var/www/html /custom_web
echo "SELinux Context Restored" > /var/www/html/index.html
chcon -t user_home_t /var/www/html/index.html

echo "Custom Web Directory" > /custom_web/custom.html
semanage fcontext -a -t httpd_sys_content_t "/custom_web(/.*)?" 2>/dev/null || \
  semanage fcontext -m -t httpd_sys_content_t "/custom_web(/.*)?"

restorecon -Rv /var/www/html /custom_web
```

### Verify
```bash
ls -Z /var/www/html/index.html | grep -c 'httpd_sys_content_t'  # expect 1
ls -Z /custom_web/custom.html  | grep -c 'httpd_sys_content_t'  # expect 1
```

**Explanation:** `semanage fcontext -a -t httpd_sys_content_t "/custom_web(/.*)?"` registers a persistent SELinux label rule, and `restorecon -Rv` applies default labels to the filesystem.

---

## Lab 10.7 — Manage SELinux port labels

### Solution
```bash
semanage port -a -t http_port_t -p tcp 82 2>/dev/null || \
  semanage port -m -t http_port_t -p tcp 82

sed -i 's/^Listen .*/Listen 82/' /etc/httpd/conf/httpd.conf
systemctl enable --now httpd
systemctl restart httpd
```

### Verify
```bash
semanage port -l | grep '^http_port_t' | grep -cw '82'   # expect 1
curl -s http://localhost:82                              # expect SELinux Context Restored
```

**Explanation:** `semanage port -a -t http_port_t -p tcp 82` grants `httpd` SELinux permission to bind to non-standard TCP port `82` (`man semanage-port` has this exact example).

---

## Lab 10.8 — Use boolean settings to modify system SELinux settings

### Solution
```bash
getsebool httpd_enable_homedirs
setsebool -P httpd_enable_homedirs on
```

### Verify
```bash
getsebool httpd_enable_homedirs              # expect httpd_enable_homedirs --> on
```

**Explanation:** `setsebool -P <boolean> on` modifies the SELinux boolean both in memory and persistently (`-P`) on disk across reboots.
