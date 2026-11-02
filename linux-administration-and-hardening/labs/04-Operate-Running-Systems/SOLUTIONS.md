# Section 4: Operate Running Systems — Solutions & Verification (10 Labs)

---

## Lab 4.1 — Boot, reboot, and shut down a system normally

### Solution
```bash
mkdir -p ~/labs/s4
shutdown -r +15 "Scheduled Exam Maintenance"
cp /run/systemd/shutdown/scheduled ~/labs/s4/scheduled_proof.txt
shutdown -c
uptime -s > ~/labs/s4/boot_time.txt
```

### Verify
```bash
grep -c 'MODE=reboot' ~/labs/s4/scheduled_proof.txt      # expect 1
ls /run/systemd/shutdown/scheduled 2>/dev/null           # expect nothing (canceled)
cat ~/labs/s4/boot_time.txt                              # expect YYYY-MM-DD HH:MM:SS
```

**Explanation:** `shutdown -r +15` schedules a clean reboot in 15 minutes (`shutdown -h +15` for halt/poweroff, `systemctl reboot` for immediate reboot), and `shutdown -c` cancels a scheduled shutdown.

---

## Lab 4.2 — Boot systems into different targets manually

### Solution
```bash
mkdir -p ~/labs/s4
systemctl set-default multi-user.target
systemctl isolate multi-user.target
systemctl get-default > ~/labs/s4/default_target.txt
```

### Verify
```bash
cat ~/labs/s4/default_target.txt             # expect multi-user.target
systemctl get-default                        # expect multi-user.target
```

**Explanation:** `systemctl set-default` configures the boot target persistently via `/etc/systemd/system/default.target`, while `systemctl isolate` switches targets immediately without rebooting.

---

## Lab 4.3 — Interrupt the boot process in order to gain access to a system

### Solution
```bash
# 1. During GRUB2 boot menu: press 'e', append 'rd.break' to the 'linux' line, press Ctrl+X:
# mount -o remount,rw /sysroot
# chroot /sysroot
# echo "root:atenorth" | chpasswd
# touch /.autorelabel
# exit
# exit

# 2. Once booted as root:
mkdir -p ~/labs/s4
echo "root:atenorth" | chpasswd
passwd -S root > ~/labs/s4/root_pw_status.txt
```

### Verify
```bash
grep -c 'Password set' ~/labs/s4/root_pw_status.txt      # expect 1
```

**Explanation:** `rd.break` stops boot right before switching root to `/sysroot`. Remounting `/sysroot` read-write, running `chroot /sysroot`, changing `root`'s password, and creating `/.autorelabel` ensures SELinux relabels `/etc/shadow` on boot.

---

## Lab 4.4 — Identify CPU/memory intensive processes and kill processes

### Solution
```bash
mkdir -p ~/labs/s4
dd if=/dev/zero of=/dev/null &
sha1sum /dev/zero &
sleep 1

ps aux --sort=-%cpu | head -n 6 > ~/labs/s4/top_cpu.txt
pkill -9 dd
pkill -9 sha1sum
```

### Verify
```bash
grep -cE 'dd|sha1sum' ~/labs/s4/top_cpu.txt  # expect >= 2
pgrep -c 'sha1sum'                           # expect 0
```

**Explanation:** `ps aux --sort=-%cpu` (or `--sort=-%mem`) sorts processes by CPU or memory usage in descending order, and `pkill` terminates processes by name.

---

## Lab 4.5 — Adjust process scheduling

### Solution
```bash
mkdir -p ~/labs/s4
pkill -f "sleep 900" 2>/dev/null || true
nice -n 5 sleep 900 &
SLEEP_PID=$!

renice -n -10 -p "$SLEEP_PID"
ps -p "$SLEEP_PID" -o pid,ni,comm --no-headers > ~/labs/s4/sleep_nice.txt
kill "$SLEEP_PID"
```

### Verify
```bash
awk '{print $2}' ~/labs/s4/sleep_nice.txt    # expect -10
cat ~/labs/s4/sleep_nice.txt
```

**Explanation:** `nice -n <VAL> <cmd>` starts a new process with nice priority `<VAL>` (`-20` to `19`), and `renice -n <VAL> -p <PID>` changes the nice priority of a running process.

---

## Lab 4.6 — Manage tuning profiles

### Solution
```bash
mkdir -p ~/labs/s4
dnf install -y tuned &>/dev/null || true
systemctl enable --now tuned
tuned-adm recommend > ~/labs/s4/recommended_profile.txt
tuned-adm profile virtual-guest
```

### Verify
```bash
tuned-adm active                             # expect Current active profile: virtual-guest
cat ~/labs/s4/recommended_profile.txt        # expect virtual-guest
```

**Explanation:** `tuned-adm recommend` shows the optimal profile for the system hardware/VM, and `tuned-adm profile <name>` activates and persists the tuning profile.

---

## Lab 4.7 — Locate and interpret system log files and journals

### Solution
```bash
mkdir -p ~/labs/s4
journalctl -b -p err > ~/labs/s4/boot_errors.log
logger -p daemon.err "EX200_JOURNAL_TEST"
sleep 1
grep "EX200_JOURNAL_TEST" /var/log/messages > ~/labs/s4/syslog_match.txt
```

### Verify
```bash
test -f ~/labs/s4/boot_errors.log && echo "OK"           # expect OK
grep -c "EX200_JOURNAL_TEST" ~/labs/s4/syslog_match.txt  # expect >= 1
```

**Explanation:** `journalctl -b -p err` filters current-boot journal messages of priority `err` (`3`), `crit` (`2`), `alert` (`1`), and `emerg` (`0`), while `rsyslog` writes system messages to `/var/log/messages`.

---

## Lab 4.8 — Preserve system journals

### Solution
```bash
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
systemctl restart systemd-journald
journalctl --flush
```

### Verify
```bash
find /var/log/journal -name "*.journal" | wc -l          # expect >= 1
```

**Explanation:** Because `/etc/systemd/journald.conf` defaults to `Storage=auto`, creating `/var/log/journal` and running `journalctl --flush` (or restarting `systemd-journald`) switches journal storage from volatile `/run/log/journal` to persistent `/var/log/journal`.

---

## Lab 4.9 — Start, stop, and check the status of network services

### Solution
```bash
mkdir -p ~/labs/s4
systemctl enable --now sshd chronyd
cat << EOF > ~/labs/s4/net_services_state.txt
sshd: $(systemctl is-active sshd) / $(systemctl is-enabled sshd)
chronyd: $(systemctl is-active chronyd) / $(systemctl is-enabled chronyd)
EOF
```

### Verify
```bash
grep -c 'active / enabled' ~/labs/s4/net_services_state.txt  # expect 2
cat ~/labs/s4/net_services_state.txt
```

**Explanation:** `systemctl enable --now <service>` both enables the service to start at boot and starts it immediately.

---

## Lab 4.10 — Securely transfer files between systems

### Solution
```bash
mkdir -p ~/labs/s4/transfer_src /var/tmp/scp_dest /var/tmp/rsync_dest
echo "File 1" > ~/labs/s4/transfer_src/config1.txt
echo "File 2" > ~/labs/s4/transfer_src/config2.txt

scp -o StrictHostKeyChecking=no -rp ~/labs/s4/transfer_src/* root@localhost:/var/tmp/scp_dest/
rsync -azAX -e "ssh -o StrictHostKeyChecking=no" ~/labs/s4/transfer_src/ root@localhost:/var/tmp/rsync_dest/
```

### Verify
```bash
ls /var/tmp/scp_dest/config1.txt /var/tmp/scp_dest/config2.txt       # expect both files
ls /var/tmp/rsync_dest/config1.txt /var/tmp/rsync_dest/config2.txt   # expect both files
```

**Explanation:** `scp -rp` copies recursively while preserving timestamps and permissions, and `rsync -azAX` synchronizes files while preserving archive attributes (`-a`), ACLs (`-A`), and SELinux contexts (`-X`).
