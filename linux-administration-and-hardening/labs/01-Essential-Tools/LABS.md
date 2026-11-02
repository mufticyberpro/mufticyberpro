# Section 1: Understand and Use Essential Tools (11 Objectives = 11 Labs)

Run this one-time section setup block before starting Section 1:

### Section 1 Setup
```bash
mkdir -p ~/labs/s1
useradd -m -s /bin/bash labuser1 2>/dev/null || true
echo "labuser1:atenorth" | chpasswd
groupadd -f labteam
```

---

## Lab 1.1 — Objective 1: Access a shell prompt and issue commands with correct syntax
**Task:**
1. Create a directory tree `~/labs/s1/projects/app1/src`, `~/labs/s1/projects/app1/bin`, `~/labs/s1/projects/app2/src`, and `~/labs/s1/projects/app2/bin` using a **single** `mkdir` command with brace expansion.
2. Write the current hostname, kernel release (`uname -r`), and today's date (`YYYY-MM-DD`) on three separate lines into `~/labs/s1/sysinfo.txt`.

---

## Lab 1.2 — Objective 2: Use input-output redirection (`>`, `>>`, `|`, `2>`, etc.)
**Task:**
1. Run `ls -l /etc/passwd /etc/shadow /no_such_file` and redirect:
   - Standard output (`stdout`) to `~/labs/s1/stdout.txt`
   - Standard error (`stderr`) to `~/labs/s1/stderr.txt`
2. Run `find /etc -name "*.conf"` and redirect **both** `stdout` and `stderr` into `~/labs/s1/all_output.txt`, while also counting how many lines were written using a pipe (`|`) to `wc -l` saved in `~/labs/s1/count.txt`.

ls -l /etc/passwd /etc/shadow /no_such_file > ~/labs/s1/stdout.txt 2> ~/labs/s1/stderr.txt

find /etc -name "*.conf" &> ~/labs/s1/all_output.txt
wc -l < ~/labs/s1/all_output.txt > ~/labs/s1/count.txt
---

## Lab 1.3 — Objective 3: Use `grep` and regular expressions to analyze text
**Task:**
1. Find all lines in `/etc/passwd` that end with `/bin/bash` and save them to `~/labs/s1/bash_users.txt`.
2. Find all active configuration lines in `/etc/login.defs` (exclude any line starting with `#` and exclude any blank/whitespace-only lines) and save them to `~/labs/s1/active_login_defs.txt`.

---

## Lab 1.4 — Objective 4: Access remote systems using SSH
**Task:**
1. Generate an Ed25519 SSH key pair for `root` at `~/.ssh/id_ed25519` with no passphrase (`-N ""`) and authorize it for `root@localhost` so you can SSH without a password.
2. Execute the remote command `hostname && touch ~/labs/s1/ssh-ok` over SSH to `root@localhost` non-interactively (`-o StrictHostKeyChecking=no`).

---

## Lab 1.5 — Objective 5: Log in and switch users in multiuser targets
**Task:**
1. Check the current systemd target (`systemctl get-default`).
2. Switch to user **`labuser1`** with a full login environment (`su - labuser1 -c ...`) and write `labuser1`'s `USER`, `UID`, and `HOME` environment variables into `/tmp/labuser1_env.txt`.

---

## Lab 1.6 — Objective 6: Archive, compress, unpack, and uncompress files using `tar`, `gzip`, and `bzip2`
**Task:**
1. Create a **gzip**-compressed tar archive of `/etc/ssh` at `~/labs/s1/ssh_backup.tar.gz`.
2. Create a **bzip2**-compressed tar archive of `/etc/ssh` at `~/labs/s1/ssh_backup.tar.bz2`.
3. Unpack `~/labs/s1/ssh_backup.tar.bz2` into `~/labs/s1/unpacked_ssh/`.

---

## Lab 1.7 — Objective 7: Create and edit text files
**Task:**
1. Create a file `~/labs/s1/servers.conf` containing three lines (`web01.lab.example.com`, `db01.lab.example.com`, `cache01.lab.example.com`).
2. Using `sed` (or `vi`), replace every occurrence of `lab.example.com` with `prod.example.com` inside `~/labs/s1/servers.conf` and append a fourth line `backup01.prod.example.com`.

---

## Lab 1.8 — Objective 8: Create, delete, copy, and move files and directories
**Task:**
1. Create 5 files inside `~/labs/s1/source_files/` named `file1.txt` through `file5.txt` owned by `labuser1:labteam`, plus one decoy file `temp.tmp`.
2. Copy all `.txt` files from `~/labs/s1/source_files/` to `~/labs/s1/backup_files/` **preserving ownership, permissions, and timestamps** (`cp -a`).
3. Move `file5.txt` from `~/labs/s1/backup_files/` to `~/labs/s1/archived_file5.txt`, and delete `~/labs/s1/source_files/temp.tmp`.

---

## Lab 1.9 — Objective 9: Create hard and soft links
**Task:**
1. Create a file `~/labs/s1/master_data.txt` containing `Important Record`.
2. Create a **hard link** to `~/labs/s1/master_data.txt` at `~/labs/s1/hard_data.txt`.
3. Create a **soft (symbolic) link** to `/root/labs/s1/master_data.txt` at `~/labs/s1/soft_data.txt`.

---

## Lab 1.10 — Objective 10: List, set, and change standard `ugo/rwx` permissions
**Task:**
1. Create a file `~/labs/s1/deploy.sh` and a directory `~/labs/s1/shared_dir`.
2. Change ownership of both to `labuser1:labteam`.
3. Set `~/labs/s1/deploy.sh` permissions so owner has `rwx`, group has `r-x`, and others have no permissions (`0750`).
4. Set `~/labs/s1/shared_dir` permissions using symbolic or octal mode so owner and group have `rwx` and others have `r-x` (`0775`).

---

## Lab 1.11 — Objective 11: Locate, read, and use system documentation including `man`, `info`, and files in `/usr/share/doc`
**Task:**
1. Update the `man` database (`mandb`), search `man -k` for keyword `crontab`, and save the output to `~/labs/s1/man_crontab.txt`.
2. Find all files named `README*` inside `/usr/share/doc` and copy the list of their file paths into `~/labs/s1/doc_readmes.txt`.
