# Section 4: Operate Running Systems (10 Objectives = 10 Labs)

> **Official RHEL 10 Objectives in Section 4 (10 Objectives):**
> 1. Boot, reboot, and shut down a system normally
> 2. Boot systems into different targets manually
> 3. Interrupt the boot process in order to gain access to a system
> 4. Identify CPU/memory intensive processes and kill processes
> 5. Adjust process scheduling
> 6. Manage tuning profiles
> 7. Locate and interpret system log files and journals
> 8. Preserve system journals
> 9. Start, stop, and check the status of network services
> 10. Securely transfer files between systems

---

## Lab 4.1 — Objective 1: Boot, reboot, and shut down a system normally
**Task:**
1. Schedule a system reboot 15 minutes in the future (`shutdown -r +15 "Scheduled Exam Maintenance"`), verify the scheduled shutdown file `/run/systemd/shutdown/scheduled`, and then cancel the pending reboot (`shutdown -c`).
2. Save the system's boot timestamp (`uptime -s`) into `~/labs/s4/boot_time.txt`.

---

## Lab 4.2 — Objective 2: Boot systems into different targets manually
**Task:**
1. Configure the system to boot into **`multi-user.target`** persistently (`systemctl set-default`) and switch the live running system into **`multi-user.target`** (`systemctl isolate`).
2. Save the output of `systemctl get-default` to `~/labs/s4/default_target.txt`.

---

## Lab 4.3 — Objective 3: Interrupt the boot process in order to gain access to a system
**Task:**
1. Interrupt the GRUB2 boot menu on `node2` (`e`), append **`rd.break`** to the `linux` kernel line, press `Ctrl+X`, remount `/sysroot` read-write, `chroot /sysroot`, reset `root`'s password to **`atenorth`**, create `/.autorelabel`, and boot the system.
2. After logging in as `root`, save `/etc/shadow`'s `root` line status (`passwd -S root`) into `~/labs/s4/root_pw_status.txt`.

---

## Lab 4.4 — Objective 4: Identify CPU/memory intensive processes and kill processes
**Task:**
1. Start two background CPU-intensive processes:
   ```bash
   dd if=/dev/zero of=/dev/null &
   sha1sum /dev/zero &
   ```
2. Find the top CPU-consuming process name and PID using `ps`, save the top 5 CPU processes into `~/labs/s4/top_cpu.txt`, and terminate both `dd` and `sha1sum` using `pkill`.

---

## Lab 4.5 — Objective 5: Adjust process scheduling
**Task:**
1. Start a background process `sleep 900 &` with an initial **nice value of `5`** (`nice -n 5 sleep 900 &`).
2. Change the running `sleep` process's nice value to **`-10`** using `renice`.
3. Save `ps -C sleep -o pid,ni,comm --no-headers` into `~/labs/s4/sleep_nice.txt` and then kill `sleep`.

---

## Lab 4.6 — Objective 6: Manage tuning profiles
**Task:**
1. Ensure the `tuned` service is enabled and started.
2. Save the output of `tuned-adm recommend` into `~/labs/s4/recommended_profile.txt`.
3. Set the active tuning profile to **`virtual-guest`** (`tuned-adm profile virtual-guest`).

---

## Lab 4.7 — Objective 7: Locate and interpret system log files and journals
**Task:**
1. Query `journalctl` for all log messages from the current boot (`-b`) with priority **`err` (`3`) or higher** and save them to `~/labs/s4/boot_errors.log`.
2. Write a custom log message `EX200_JOURNAL_TEST` using `logger -p daemon.err "EX200_JOURNAL_TEST"` and extract that exact entry from `/var/log/messages` into `~/labs/s4/syslog_match.txt`.

---

## Lab 4.8 — Objective 8: Preserve system journals
**Task:**
1. Configure `systemd-journald` so system journals are stored persistently on disk across reboots under `/var/log/journal`.
2. Restart `systemd-journald` and flush the runtime journal to `/var/log/journal` (`journalctl --flush`).

---

## Lab 4.9 — Objective 9: Start, stop, and check the status of network services
**Task:**
1. Ensure `sshd` and `chronyd` are enabled at boot and currently active (`systemctl enable --now`).
2. Save the active/enabled states of `sshd` and `chronyd` into `~/labs/s4/net_services_state.txt`.

---

## Lab 4.10 — Objective 10: Securely transfer files between systems
**Task:**
1. Create a directory `~/labs/s4/transfer_src/` containing `config1.txt` and `config2.txt`.
2. Transfer `~/labs/s4/transfer_src/` to `root@localhost:/var/tmp/scp_dest/` using **`scp -rp`** and to `root@localhost:/var/tmp/rsync_dest/` using **`rsync -azAX`**.
