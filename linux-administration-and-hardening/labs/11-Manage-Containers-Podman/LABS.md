# Category 11: Manage Containers (Rootless Podman & Quadlets) — Practice Labs

> **Official Objectives Covered (RHEL 10):**
> - Find and retrieve container images from a remote registry (`podman search`, `podman pull`)
> - Inspect container images (`podman inspect`, `skopeo inspect`)
> - Build a container from a `Containerfile` (`podman build`)
> - Perform basic container management (`podman run`, `start`, `stop`, `ps`, `rm`, `logs`, `exec`)
> - Run a service inside a container (port mapping `-p`, environment variables `-e`)
> - Attach persistent storage to a container (`-v /host:/container:Z`, `podman unshare`)
> - Configure a container to start automatically as a `systemd` service (**RHEL 10 Podman Quadlets** & `systemctl --user` + `loginctl enable-linger`)

---

### Pre-Lab Rule (Read Before Starting!)
Whenever working with **rootless** containers for a non-root user (such as `aloha`), **ALWAYS log in via `ssh aloha@localhost`**, NEVER via `su - aloha`! Using `su -` does not initialize the user's `XDG_RUNTIME_DIR` (`/run/user/<UID>`) or D-Bus session, which causes `podman` and `systemctl --user` to fail.

---

## Lab 11.1: Searching, Inspecting (`skopeo` & `podman`), Pulling, and Saving/Loading Images
**Scenario:**
Log in as user **`aloha`** (`ssh aloha@localhost`, password: `atenorth`):
1. Search registries for **`httpd`** images using `podman search`.
2. Without pulling the image first, inspect the remote image metadata and exposed ports of `docker.io/library/httpd:latest` using **`skopeo inspect`** (if installed) or pull it with `podman pull` and inspect it with **`podman image inspect`**.
3. Save the image `docker.io/library/httpd:latest` to a tar archive at **`/home/aloha/httpd_image.tar`** (`podman save`) and verify you can load it back (`podman load`).

---

## Lab 11.2: Building a Custom Container Image from a `Containerfile` (`podman build`)
**Scenario:**
As user **`aloha`**:
1. Create a directory `/home/aloha/custom_build/` containing a `Containerfile` that:
   - Starts `FROM docker.io/library/httpd:latest`
   - Sets an environment variable `ENV APP_ENV=production`
   - Creates a custom default web page by running `RUN echo "Built via RHEL 10 Containerfile" > /usr/local/apache2/htdocs/info.html`
   - Exposes port `80` (`EXPOSE 80`)
2. Build the container image and tag it as **`localhost/webapp:v1.0`**.
3. Verify the image exists in `podman images`.

---

## Lab 11.3: Running Rootless Containers with Port Mapping (`-p`) and Environment Variables (`-e`)
**Scenario:**
As user **`aloha`**:
1. Run a detached (`-d`) container named **`test_env_web`** from image **`localhost/webapp:v1.0`** with:
   - Host port **`8081`** mapped to container port **`80`**.
   - Environment variables **`DB_HOST=node2.lab.example.com`** and **`LOG_LEVEL=debug`**.
2. Verify the container is running (`podman ps`), check its environment variables using `podman exec test_env_web env`, and verify `curl http://localhost:8081/info.html`.
3. Stop and remove `test_env_web` cleanly.

---

## Lab 11.4: Attaching Persistent Host Storage (`-v ...:Z`) and Fixing Rootless UID Ownership (`podman unshare`)
**Scenario:**
As user **`aloha`**:
1. Create the host directory **`/home/aloha/persistent_html`** and create `/home/aloha/persistent_html/index.html` containing `Persistent Storage Verified`.
2. Check what UID/GID the container's default user runs as (`podman inspect --format '{{.Config.User}}' localhost/webapp:v1.0`). If a container runs as a non-root UID inside the container (like UID `1001` or `apache` UID `48`), practice changing ownership of `/home/aloha/persistent_html` inside the user namespace using **`podman unshare chown`**.
3. Run a detached container named **`logserver`** from `localhost/webapp:v1.0` mapping host port **`8080:80`** and mounting `/home/aloha/persistent_html` to `/usr/local/apache2/htdocs` with the **`:Z`** SELinux flag.

---

## Lab 11.5: Configuring a Rootless Container as a Persistent Systemd Service on RHEL 10 (Quadlet + `loginctl enable-linger`)
**Scenario:**
Configure the **`logserver`** container for user **`aloha`** so that it starts automatically when the system boots, even if `aloha` never logs in:
1. Enable user lingering for `aloha` (`loginctl enable-linger aloha`).
2. Configure a **RHEL 10 Podman Quadlet** file at **`/home/aloha/.config/containers/systemd/logserver.container`** (and also know the `podman generate systemd --name logserver --files --new` fallback method).
3. Reload the user systemd daemon (`systemctl --user daemon-reload`), start `logserver.service`, reboot the VM, and verify that `podman ps` (as `aloha`) and `curl http://localhost:8080` work immediately after reboot!

