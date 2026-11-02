# Section 6: Create and Configure File Systems (5 Objectives = 5 Labs)

> **Official RHEL 10 Objectives in Section 6 (5 Objectives):**
> 1. Create, mount, unmount, and use `vfat`, `ext4`, and `xfs` file systems
> 2. Mount and unmount network file systems using NFS
> 3. Configure `autofs`
> 4. Extend existing logical volumes
> 5. Create and configure set-GID directories for collaboration

---

### Section 6 Setup (Run once before starting Section 6 — uses `vg_s5` from Section 5 or creates `/dev/loop6` automatically)
```bash
mkdir -p ~/labs/s6
if ! vgs vg_s5 &>/dev/null; then
    fallocate -l 4G /var/tmp/s5_disk.img
    losetup /dev/loop6 /var/tmp/s5_disk.img 2>/dev/null || true
    parted -s /dev/loop6 mklabel gpt mkpart primary 1MiB 3500MiB set 1 lvm on
    partprobe /dev/loop6 && udevadm settle
    pvcreate -f /dev/loop6p1 && vgcreate -s 16M vg_s5 /dev/loop6p1
fi
dnf install -y dosfstools nfs-utils autofs acl &>/dev/null || true
```

---

## Lab 6.1 — Objective 1: Create, mount, unmount, and use `vfat`, `ext4`, and `xfs` file systems
**Task:**
1. Create three `160 MiB` Logical Volumes in `vg_s5`: `lv_vfat`, `lv_ext4`, and `lv_xfs`.
2. Format `lv_vfat` as **`vfat`**, `lv_ext4` as **`ext4`**, and `lv_xfs` as **`xfs`**.
3. Mount them at `/mnt/s6_vfat`, `/mnt/s6_ext4`, and `/mnt/s6_xfs`, write a file `test.txt` inside each, then unmount `/mnt/s6_vfat` (`umount /mnt/s6_vfat`) and remount it.

---

## Lab 6.2 — Objective 2: Mount and unmount network file systems using NFS
**Task:**
1. Create an NFS export directory `/srv/nfs/s6_share` containing `nfs_ok.txt`, export it in `/etc/exports` (`*(rw,sync,no_root_squash)`), and start `nfs-server`.
2. Mount `127.0.0.1:/srv/nfs/s6_share` persistently at **`/mnt/s6_nfs`** via `/etc/fstab` (`nfs`, `rw,sync,_netdev,nofail`).

---

## Lab 6.3 — Objective 3: Configure `autofs`
**Task:**
1. Create an NFS export directory `/srv/nfs/s6_homes/ldapuser1` containing `welcome.txt`.
2. Configure `autofs` via `/etc/auto.master.d/s6_homes.autofs` and `/etc/auto.s6_homes` so that accessing **`/s6_homes/ldapuser1`** automatically mounts `127.0.0.1:/srv/nfs/s6_homes/ldapuser1` with `-rw,sync` options.

---

## Lab 6.4 — Objective 4: Extend existing logical volumes
**Task:**
1. Without unmounting `/mnt/s6_ext4` or `/mnt/s6_xfs` and without losing `test.txt` on either filesystem:
   - Extend `/dev/vg_s5/lv_ext4` and its `ext4` filesystem from `160 MiB` to **`320 MiB`** (`lvextend -r -L 320M`).
   - Extend `/dev/vg_s5/lv_xfs` and its `xfs` filesystem from `160 MiB` to **`320 MiB`** (`lvextend -r -L 320M`).

---

## Lab 6.5 — Objective 5: Create and configure set-GID directories for collaboration
**Task:**
1. Create a group **`s6_collab`** and two users **`s6_alice`** and **`s6_bob`** who belong to `s6_collab`.
2. Create the directory **`/srv/s6_team`**:
   - Group ownership set to **`s6_collab`**.
   - Mode set to **`2770`** (`rwxrws---`) so members of `s6_collab` have full access, others have zero access, and any file created inside `/srv/s6_team` automatically inherits the `s6_collab` group.
3. Also configure an ACL on `/srv/s6_team` granting user **`labuser1`** read-and-execute (`r-x`) access (`setfacl -m u:labuser1:r-x /srv/s6_team`).
