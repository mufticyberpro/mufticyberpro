# Section 3: Create Simple Shell Scripts (4 Objectives = 4 Labs)

> **Official RHEL 10 Objectives in Section 3 (4 Objectives):**
> 1. Conditionally execute code (use of: `if`, `test`, `[]`, etc.)
> 2. Use Looping constructs (`for`, etc.) to process file, command line input
> 3. Process script inputs (`$1`, `$2`, etc.)
> 4. Processing output of shell commands within a script

---

## Lab 3.1 — Objective 1: Conditionally execute code (use of: `if`, `test`, `[]`, etc.)
**Task:**
Create an executable script at `~/labs/s3/check_path.sh` (`chmod 755`):
- If `/var/tmp/maintenance.flag` exists (`[[ -f /var/tmp/maintenance.flag ]]`), the script writes `MAINTENANCE_MODE` to `~/labs/s3/mode.txt`.
- Otherwise (`else`), the script writes `NORMAL_MODE` to `~/labs/s3/mode.txt`.
- Test both branches by creating `/var/tmp/maintenance.flag` and running the script.

---

## Lab 3.2 — Objective 2: Use Looping constructs (`for`, etc.) to process file, command line input
**Task:**
1. Create a file `~/labs/s3/folders.txt` containing 4 directory names (`alpha`, `bravo`, `charlie`, `delta`).
2. Create an executable script `~/labs/s3/make_dirs.sh` that uses a `for` loop to read each name from `~/labs/s3/folders.txt` and creates `~/labs/s3/output_dirs/<name>/README.txt` containing `Directory: <name>`.
3. Run `~/labs/s3/make_dirs.sh`.

---

## Lab 3.3 — Objective 3: Process script inputs (`$1`, `$2`, etc.)
**Task:**
Create an executable script at `/usr/local/bin/ex200_arg.sh` (`chmod 755`):
- If `$1` is `redhat`, output `fedora`.
- If `$1` is `fedora`, output `redhat`.
- If `$1` is anything else or missing, output `Usage: /usr/local/bin/ex200_arg.sh redhat|fedora` to standard error (`>&2`) and exit with status `1`.

---

## Lab 3.4 — Objective 4: Processing output of shell commands within a script
**Task:**
Create an executable script at `~/labs/s3/suid_audit.sh` (`chmod 755`):
- Uses command substitution `$(...)` to count how many regular files under `/usr/bin` have the SUID bit (`-perm -4000`) set.
- Saves the list of those files to `~/labs/s3/suid_list.txt`.
- Writes a summary line `Found <COUNT> SUID files on <HOSTNAME>` to `~/labs/s3/suid_summary.txt`.
- Run `~/labs/s3/suid_audit.sh`.
