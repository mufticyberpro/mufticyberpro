# Section 5: Configure Local Storage (6 Objectives = 6 Labs)

> **Official RHEL 10 Objectives in Section 5 (6 Objectives):**
> 1. List, create, delete partitions on MBR and GPT disks
> 2. Create and remove physical volumes
> 3. Assign physical volumes to volume groups
> 4. Create and delete logical volumes
> 5. Configure systems to mount file systems at boot by universally unique ID (`UUID`) or label
> 6. Add new partitions and logical volumes, and swap to a system non-destructively

---

### Section 5 Setup (Run once before starting Section 5 — creates a safe 4 GiB loopback disk `/dev/loop6` so you can copy-paste every command identically on any VM!)
```bash
mkdir -p ~/labs/s5
umount /mnt/s5_uuid /mnt/s5_label 2>/dev/null || true
swapoff /dev/vg_s5/lv_s5_swap 2>/dev/null || true
vgremove -ff vg_s5 2>/dev/null || true
losetup -d /dev/loop6 2>/dev/null || true
rm -f /var/tmp/s5_disk.img
fallocate -l 4G /var/tmp/s5_disk.img
losetup /dev/loop6 /var/tmp/s5_disk.img
```

---

## Lab 5.1 — Objective 1: List, create, delete partitions on MBR and GPT disks
**Task:**
Using `/dev/loop6`:
1. Create a **`gpt`** partition table label on `/dev/loop6`.
2. Create three partitions:
   - Partition 1 (`/dev/loop6p1`): `1MiB` to `1025MiB` (`1 GiB`), flagged `lvm`
   - Partition 2 (`/dev/loop6p2`): `1025MiB` to `2049MiB` (`1 GiB`), flagged `lvm`
   - Partition 3 (`/dev/loop6p3`): `2049MiB` to `2561MiB` (`512 MiB`)
3. Delete Partition 3 (`/dev/loop6p3`) and recreate it from `2049MiB` to `3073MiB` (`1 GiB`), flagged `lvm`.

---

## Lab 5.2 — Objective 2: Create and remove physical volumes
**Task:**
1. Initialize `/dev/loop6p1`, `/dev/loop6p2`, and `/dev/loop6p3` as LVM Physical Volumes (`pvcreate`).
2. Remove the LVM Physical Volume label from `/dev/loop6p3` (`pvremove`) and then re-initialize `/dev/loop6p3` with `pvcreate`.

---

## Lab 5.3 — Objective 3: Assign physical volumes to volume groups
**Task:**
1. Create a Volume Group named **`vg_s5`** with a Physical Extent (PE) size of **`16 MiB`** (`-s 16M`) using `/dev/loop6p1`.
2. Extend Volume Group **`vg_s5`** by adding `/dev/loop6p2` to it (`vgextend`).

---

## Lab 5.4 — Objective 4: Create and delete logical volumes
**Task:**
1. Create three Logical Volumes inside **`vg_s5`**:
   - **`lv_s5_data`**: size **`30` extents** (`-l 30`, which equals `480 MiB`)
   - **`lv_s5_logs`**: size **`320 MiB`** (`-L 320M`)
   - **`lv_s5_temp`**: size **`160 MiB`** (`-L 160M`)
2. Delete the Logical Volume **`lv_s5_temp`** (`lvremove -y`).

---

## Lab 5.5 — Objective 5: Configure systems to mount file systems at boot by universally unique ID (`UUID`) or label
**Task:**
1. Format `/dev/vg_s5/lv_s5_data` as **`xfs`** with label **`S5_DATA`** and mount it persistently at **`/mnt/s5_uuid`** using its **`UUID=`** in `/etc/fstab`.
2. Format `/dev/vg_s5/lv_s5_logs` as **`ext4`** with label **`S5_LOGS`** and mount it persistently at **`/mnt/s5_label`** using **`LABEL=S5_LOGS`** in `/etc/fstab`.

---

## Lab 5.6 — Objective 6: Add new partitions and logical volumes, and swap to a system non-destructively
**Task:**
1. Non-destructively add `/dev/loop6p3` into `vg_s5` (`vgextend`).
2. Create a **`512 MiB`** Logical Volume named **`lv_s5_swap`** in `vg_s5`, format it as swap (`mkswap`), add it persistently by `UUID=` to `/etc/fstab`, and activate it (`swapon -a`).
