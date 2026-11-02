# Section 7: Deploy, Configure, and Maintain Systems — Solutions & Verification (6 Labs)

---

## Lab 7.1 — Schedule tasks using `at` and `cron`

### Solution
```bash
mkdir -p ~/labs/s7
id labuser1 &>/dev/null || useradd labuser1
dnf install -y cronie at &>/dev/null || true
systemctl enable --now crond atd

echo '*/2 * * * * /usr/bin/logger "EX200_CRON_OK"' | crontab -u labuser1 -
echo "touch /var/tmp/at_scheduled.ok" | at now + 10 minutes
```

### Verify
```bash
crontab -u labuser1 -l | grep -c 'EX200_CRON_OK'         # expect 1
atq | wc -l                                              # expect >= 1
```

**Explanation:** `crontab -u <user> -` installs a user crontab schedule, and `echo "<cmd>" | at now + 10 minutes` queues a one-time job via `atd`.

---

## Lab 7.2 — Start and stop services and configure services to start automatically at boot

### Solution
```bash
dnf install -y httpd &>/dev/null || true
systemctl enable --now httpd crond

cat << 'EOF' > /etc/systemd/system/s7-dummy.service
[Unit]
Description=Dummy Service for Section 7

[Service]
ExecStart=/usr/bin/sleep 3600

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now s7-dummy.service
systemctl disable --now s7-dummy.service
```

### Verify
```bash
systemctl is-enabled httpd crond             # expect enabled / enabled
systemctl is-active s7-dummy.service         # expect inactive
systemctl is-enabled s7-dummy.service        # expect disabled
```

**Explanation:** `systemctl enable --now` enables a unit at boot and starts it immediately; `systemctl disable --now` disables it at boot and stops it immediately.

---

## Lab 7.3 — Configure systems to boot into a specific target automatically

### Solution
```bash
mkdir -p ~/labs/s7
systemctl set-default multi-user.target
readlink -f /etc/systemd/system/default.target > ~/labs/s7/target_link.txt
```

### Verify
```bash
systemctl get-default                                    # expect multi-user.target
grep -c 'multi-user.target' ~/labs/s7/target_link.txt    # expect 1
```

**Explanation:** `systemctl set-default multi-user.target` points `/etc/systemd/system/default.target` to `/usr/lib/systemd/system/multi-user.target`.

---

## Lab 7.4 — Configure time service clients

### Solution
```bash
dnf install -y chrony &>/dev/null || true
timedatectl set-timezone UTC
mkdir -p /etc/chrony.d
echo "server time.cloudflare.com iburst" > /etc/chrony.d/exam-ntp.conf
systemctl enable --now chronyd
systemctl restart chronyd
timedatectl set-ntp true
```

### Verify
```bash
timedatectl show -p Timezone --value                     # expect UTC
grep -c 'time.cloudflare.com' /etc/chrony.d/exam-ntp.conf # expect 1
systemctl is-active chronyd                              # expect active
```

**Explanation:** Drop-in files ending in `.conf` inside `/etc/chrony.d/` (or lines in `/etc/chrony.conf`) configure NTP time servers for `chronyd`.

---

## Lab 7.5 — Install and update software packages from Red Hat Network, a remote repository, or from the local file system

### Solution
```bash
mount /dev/sr0 /mnt/disc 2>/dev/null || true
RPM_FILE=$(find /mnt/disc/BaseOS/Packages -name "tree-[0-9]*.rpm" | head -n1)
if [[ -n "$RPM_FILE" ]]; then
    dnf install -y "$RPM_FILE"
else
    dnf install -y tree
fi
```

### Verify
```bash
rpm -q tree                                  # expect tree-<version>
command -v tree                              # expect /usr/bin/tree
```

**Explanation:** `dnf install -y /path/to/package.rpm` installs an RPM directly from the local filesystem while still resolving any dependencies from enabled repositories.

---

## Lab 7.6 — Modify the system bootloader

### Solution
```bash
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg
grubby --update-kernel=DEFAULT --args="rd.info=1"
```

### Verify
```bash
grep '^GRUB_TIMEOUT=5' /etc/default/grub                 # expect GRUB_TIMEOUT=5
grubby --info=DEFAULT | grep -c 'rd.info=1'              # expect 1
```

**Explanation:** `grub2-mkconfig -o /boot/grub2/grub.cfg` updates the GRUB2 configuration from `/etc/default/grub`, and `grubby --update-kernel=DEFAULT --args="..."` adds kernel command-line arguments to the BLS boot entry.
