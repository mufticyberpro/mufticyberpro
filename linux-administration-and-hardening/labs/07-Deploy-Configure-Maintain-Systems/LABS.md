# Section 7: Deploy, Configure, and Maintain Systems (6 Objectives = 6 Labs)

> **Official RHEL 10 Objectives in Section 7 (6 Objectives):**
> 1. Schedule tasks using `at` and `cron`
> 2. Start and stop services and configure services to start automatically at boot
> 3. Configure systems to boot into a specific target automatically
> 4. Configure time service clients
> 5. Install and update software packages from Red Hat Network, a remote repository, or from the local file system
> 6. Modify the system bootloader

---

## Lab 7.1 — Objective 1: Schedule tasks using `at` and `cron`
**Task:**
1. Configure a recurring `cron` job for user **`labuser1`** that runs every **2 minutes** (`*/2 * * * *`) and executes `/usr/bin/logger "EX200_CRON_OK"`.
2. Ensure `atd` is enabled and running, and schedule a one-time `at` job for `root` at `now + 10 minutes` that runs `touch /var/tmp/at_scheduled.ok`.

---

## Lab 7.2 — Objective 2: Start and stop services and configure services to start automatically at boot
**Task:**
1. Enable and start the **`httpd`** and **`crond`** services so they run now and start automatically at boot.
2. Stop and disable the **`bluetooth`** (or **`cups`** / a custom dummy service `s7-dummy.service`) so it does not start at boot.

---

## Lab 7.3 — Objective 3: Configure systems to boot into a specific target automatically
**Task:**
1. Configure the system to boot automatically into **`multi-user.target`** on every reboot (`systemctl set-default multi-user.target`).
2. Save the symlink target of `/etc/systemd/system/default.target` (`readlink -f /etc/systemd/system/default.target`) to `~/labs/s7/target_link.txt`.

---

## Lab 7.4 — Objective 4: Configure time service clients
**Task:**
1. Set the system timezone to **`UTC`** using `timedatectl`.
2. Configure `chronyd` by creating `/etc/chrony.d/exam-ntp.conf` containing `server time.cloudflare.com iburst`, enable NTP synchronization (`timedatectl set-ntp true`), and restart `chronyd`.

---

## Lab 7.5 — Objective 5: Install and update software packages from Red Hat Network, a remote repository, or from the local file system
**Task:**
1. Locate an `.rpm` file directly on the mounted local filesystem `/mnt/disc/BaseOS/Packages/` (such as `tree*.rpm` or `dos2unix*.rpm`) and install it directly from its local `.rpm` file path using `dnf install -y /mnt/disc/BaseOS/Packages/tree-*.rpm`.

---

## Lab 7.6 — Objective 6: Modify the system bootloader
**Task:**
1. Set `GRUB_TIMEOUT=5` in `/etc/default/grub` and regenerate `/boot/grub2/grub.cfg` using `grub2-mkconfig`.
2. Using `grubby`, append the kernel argument **`rd.info=1`** to the default kernel (`grubby --update-kernel=DEFAULT --args="rd.info=1"`).
