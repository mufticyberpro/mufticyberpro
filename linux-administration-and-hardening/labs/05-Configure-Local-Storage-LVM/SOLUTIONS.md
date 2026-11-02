# Section 5: Configure Local Storage — Solutions & Verification (6 Labs)

---

## Lab 5.1 — List, create, delete partitions on MBR and GPT disks

### Solution
```bash
parted -s /dev/loop6 mklabel gpt
parted -s /dev/loop6 mkpart primary 1MiB 1025MiB
parted -s /dev/loop6 set 1 lvm on
parted -s /dev/loop6 mkpart primary 1025MiB 2049MiB
parted -s /dev/loop6 set 2 lvm on
parted -s /dev/loop6 mkpart primary 2049MiB 2561MiB

# Delete partition 3 and recreate as 1GiB LVM partition:
parted -s /dev/loop6 rm 3
parted -s /dev/loop6 mkpart primary 2049MiB 3073MiB
parted -s /dev/loop6 set 3 lvm on
partprobe /dev/loop6
udevadm settle
```

### Verify
```bash
lsblk -no NAME /dev/loop6 | grep -c 'loop6p' # expect 3
parted -s /dev/loop6 print
```

**Explanation:** `parted -s <disk> mklabel gpt` creates a GPT partition table (`mklabel msdos` for MBR), `mkpart` creates partitions on MiB boundaries, and `rm <N>` deletes partition `N`.

---

## Lab 5.2 — Create and remove physical volumes

### Solution
```bash
pvcreate /dev/loop6p1 /dev/loop6p2 /dev/loop6p3
pvremove -y /dev/loop6p3
pvcreate /dev/loop6p3
```

### Verify
```bash
pvs --noheadings -o pv_name | grep -c '/dev/loop6p'      # expect 3
pvs
```

**Explanation:** `pvcreate` writes the LVM Physical Volume header onto partitions, and `pvremove` wipes the PV metadata from an unused partition.

---

## Lab 5.3 — Assign physical volumes to volume groups

### Solution
```bash
vgcreate -s 16M vg_s5 /dev/loop6p1
vgextend vg_s5 /dev/loop6p2
```

### Verify
```bash
vgs --noheadings -o vg_extent_size --units m vg_s5       # expect 16.00m
vgs --noheadings -o pv_count vg_s5                       # expect 2
```

**Explanation:** `vgcreate -s 16M` sets the Volume Group's Physical Extent size to `16 MiB`, and `vgextend` adds another Physical Volume into the Volume Group.

---

## Lab 5.4 — Create and delete logical volumes

### Solution
```bash
lvcreate -l 30 -n lv_s5_data vg_s5
lvcreate -L 320M -n lv_s5_logs vg_s5
lvcreate -L 160M -n lv_s5_temp vg_s5

lvremove -y /dev/vg_s5/lv_s5_temp
```

### Verify
```bash
lvs --noheadings -o lv_size --units m /dev/vg_s5/lv_s5_data  # expect 480.00m
lvs --noheadings -o lv_size --units m /dev/vg_s5/lv_s5_logs  # expect 320.00m
lvs /dev/vg_s5/lv_s5_temp 2>/dev/null                        # expect nothing (deleted)
```

**Explanation:** Lowercase `-l` specifies the number of extents (`30 * 16M = 480M`), uppercase `-L` specifies the size (`320M`), and `lvremove -y` deletes a Logical Volume.

---

## Lab 5.5 — Configure systems to mount file systems at boot by universally unique ID (`UUID`) or label

### Solution
```bash
mkfs.xfs -f -L S5_DATA /dev/vg_s5/lv_s5_data
mkfs.ext4 -F -L S5_LOGS /dev/vg_s5/lv_s5_logs

mkdir -p /mnt/s5_uuid /mnt/s5_label
sed -i '\|/mnt/s5_|d' /etc/fstab

UUID_DATA=$(blkid -s UUID -o value /dev/vg_s5/lv_s5_data)
echo "UUID=${UUID_DATA}  /mnt/s5_uuid   xfs   defaults,nofail  0 0" >> /etc/fstab
echo "LABEL=S5_LOGS      /mnt/s5_label  ext4  defaults,nofail  0 0" >> /etc/fstab

systemctl daemon-reload
mount -a
```

### Verify
```bash
findmnt -no FSTYPE /mnt/s5_uuid              # expect xfs
findmnt -no FSTYPE /mnt/s5_label             # expect ext4
```

**Explanation:** `blkid -s UUID -o value <dev>` extracts the raw UUID for `/etc/fstab`, and `-L <LABEL>` sets the filesystem label during `mkfs.xfs` or `mkfs.ext4`.

---

## Lab 5.6 — Add new partitions and logical volumes, and swap to a system non-destructively

### Solution
```bash
vgextend vg_s5 /dev/loop6p3
lvcreate -L 512M -n lv_s5_swap vg_s5
mkswap /dev/vg_s5/lv_s5_swap

sed -i '\|lv_s5_swap|d' /etc/fstab
UUID_SWAP=$(blkid -s UUID -o value /dev/vg_s5/lv_s5_swap)
echo "UUID=${UUID_SWAP}  swap  swap  defaults,nofail  0 0" >> /etc/fstab

systemctl daemon-reload
swapon -a
```

### Verify
```bash
swapon --show | grep -c 'dm-'                # expect >= 1
grep -c "$UUID_SWAP" /etc/fstab              # expect 1
```

**Explanation:** `mkswap` formats the partition/LV as swap space, and adding `UUID=... swap swap defaults 0 0` to `/etc/fstab` followed by `swapon -a` activates it persistently.
