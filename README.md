# ns8-gitlab

[GitLab Community Edition](https://about.gitlab.com/) module for **NethServer 8 (NS8)**.

- **GitHub Repository:** [`https://github.com/BLS-ISP/NS8-GitLab`](https://github.com/BLS-ISP/NS8-GitLab)
- **Container Image:** `ghcr.io/bls-isp/gitlab`
- **NS8 Software Center Repository URL:** `https://raw.githubusercontent.com/BLS-ISP/ns8-nethforge/repomd/ns8/updates/`
- **License:** [GPL-3.0-or-later](LICENSE)

---

## Features

- **GitLab CE (`19.5.1-ce.0`)** running in a rootless Podman pod behind the NS8 Traefik reverse proxy
- **Let's Encrypt & HTTP-to-HTTPS redirect** configurable via the NS8 Web UI
- **NS8 LDAP / Active Directory integration** (automatic user authentication via NS8 user domains and `Ldapproxy`, including `user-domain-changed` event handler)
- **NS8 Smarthost / SMTP integration** (automatic discovery and reload on `smarthost-changed` events)
- **Git over SSH** (automatically allocates a dedicated TCP port, opens it in the NS8 node firewall via `node:fwadm`, and configures `gitlab_shell_ssh_port`)
- **Integrated GitLab Container Registry** (optional, exposed on a separate FQDN via Traefik)
- **Integrated GitLab Runner (`v19.5.1`)** (optional toggle in UI; enables `podman.socket` and automatically registers the instance runner in the background using the `glrt-` runner authentication token workflow once GitLab is ready)
- **Custom Disk / Volume Selection** (`org.nethserver.volumes` label unlocks NS8 disk selection for `gitlab-data`, `gitlab-config`, `gitlab-logs`, and `gitlab-runner-config`)
- **Backup, Restore & Clone/Move** (`module-dump-state`, `module-cleanup-state`, `restore-module` with `40restoreDB`, `clone-module`, and `update-module` support)

---

## Install via NethServer 8 Software Center UI (Recommended)

1. Open the **NethServer 8 Cluster Admin UI**.
2. Go to **Software center → Settings → Software repositories → Add repository**.
3. Enter the following details:
   - **Name:** `bls-isp`
   - **URL:** `https://raw.githubusercontent.com/BLS-ISP/ns8-nethforge/repomd/ns8/updates/`
   - **Status:** Enabled
4. Open **Software center**, find **GitLab**, and click **Install** (you can optionally expand **Configure additional volumes** during installation to place `gitlab-data` on a dedicated disk).
5. Future module updates published with a newer Semantic Version tag (e.g. `1.0.5`, `1.1.0`) will automatically appear in the **Software center → Updates** view.

> **Tip:** To clear the 1-hour repository metadata cache on NS8 and immediately see a newly published release:
> ```bash
> redis-cli del cluster/repository_cache/bls-isp
> ```

---

## Install via CLI

Instantiate the module using a **Semantic Version tag** (do not use `:latest` in production, as NS8 skips UI updates for `:latest` development instances):

```bash
add-module ghcr.io/bls-isp/gitlab:1.0.5 1
```

The output of the command will return the instance name:

```json
{"module_id": "gitlab1", "image_name": "gitlab", "image_url": "ghcr.io/bls-isp/gitlab:1.0.5"}
```

---

## Configure

Assuming the instance is named `gitlab1`, you can configure it directly in the **NethServer 8 Web UI** (**Settings → gitlab1**) or via CLI using `configure-module`:

- `host`: Fully qualified domain name for the GitLab web interface (e.g. `git.example.org`)
- `http2https`: Redirect HTTP requests to HTTPS (`true` / `false`)
- `lets_encrypt`: Request a valid Let's Encrypt certificate (`true` / `false`)
- `password`: Root password for the `root` administrator account (optional, minimum 8 characters). If left empty during initial setup, the module generates a random password and stores it in `state/passwords.env` (mode `0600`). You can either set a new `root` password at any time in the module **Settings** page or retrieve the generated password on the NS8 node via:
  ```bash
  runagent -m gitlab1 grep '^GITLAB_INITIAL_PASSWORD=' passwords.env
  ```
- `ldap_domain`: NS8 LDAP / Active Directory domain for user authentication (optional)
- `registry_host`: Fully qualified domain name for the GitLab Container Registry (optional, e.g. `registry.example.org`)
- `runner_enabled`: Enable and auto-register the integrated GitLab Runner container (`true` / `false`)

> [!WARNING]
> **Security Notice — Integrated GitLab Runner:**
> When `runner_enabled` is enabled, CI jobs run inside containers spawned through the module's rootless Podman socket (`%t/podman/podman.sock`). Because CI jobs have access to this Podman socket, a job can control `gitlab-app` and read its volumes or secrets. Only enable the integrated runner when all users with CI/CD pipeline permissions on the GitLab instance are trusted, or use an external runner on a dedicated host for untrusted projects.

Example CLI invocation:

```bash
api-cli run module/gitlab1/configure-module --data '{
  "host": "git.example.org",
  "http2https": true,
  "lets_encrypt": true,
  "password": "MyStrongRootPassword123!",
  "ldap_domain": "",
  "registry_host": "registry.example.org",
  "runner_enabled": true
}'
```

> **Note on first startup:** On initial boot, GitLab Omnibus initializes PostgreSQL, Gitaly, Redis, and runs all database migrations. This takes approximately **3 to 5 minutes** depending on hardware. The assigned **Git SSH port** is opened automatically in the node firewall and displayed at the top of the module settings page.

---

## Architecture, Volumes & Environment Variables (Developer / Support Reference)

### Systemd User Units (`imageroot/systemd/user/`)

- `gitlab.service`: Manages the rootless Podman pod (`gitlab`) with 512 MB `/dev/shm` and port mappings (`GITLAB_NGINX_PORT:80`, `GITLAB_REGISTRY_PORT:5050`, `GITLAB_SSH_PORT:22`).
- `gitlab-app.service`: Runs the `docker.io/gitlab/gitlab-ce:19.5.1-ce.0` container inside the pod. Executes `../bin/write-config` prior to startup to render `state/gitlab.rb` (mode `0600`) from `state/environment`, `state/passwords.env`, NethServer 8 `Ldapproxy`, and Redis smarthost settings.
- `gitlab-runner.service`: Optional container (`docker.io/gitlab/gitlab-runner:v19.5.1`) attached to the rootless `podman.socket` (`%t/podman/podman.sock`).
- `gitlab-runner-register.service`: Oneshot background service (`RemainAfterExit=yes`) that waits for `http://127.0.0.1:80/-/readiness` inside `gitlab-app`, generates a `glrt-` runner authentication token via `Ci::Runners::CreateRunnerService`, and registers the runner automatically.

### Persistent Volumes & State Files (`imageroot/etc/state-include.conf` & `org.nethserver.volumes`)

| Volume / Path | Container Mountpoint | Description | Included in Backup |
|---|---|---|---|
| `volumes/gitlab-data` | `/var/opt/gitlab` | Git repositories (Gitaly), PostgreSQL database, Redis state, registry storage | Yes |
| `volumes/gitlab-config` | `/etc/gitlab` | Omnibus configuration (`gitlab.rb`), `gitlab-secrets.json`, SSH host keys | Yes |
| `volumes/gitlab-runner-config` | `/etc/gitlab-runner` | Registered runner configuration (`config.toml`) | Yes |
| `volumes/gitlab-logs` | `/var/log/gitlab` | Service and application logs | No |
| `state/passwords.env` | — | Module secrets (`GITLAB_INITIAL_PASSWORD`, mode `0600`) | Yes |
| `state/environment` | — | Non-secret module instance environment variables | Yes (implicit) |

### Environment Variables (`state/environment` & `state/passwords.env`)

| Variable | File | Description |
|---|---|---|
| `HOST` | `state/environment` | Configured FQDN for the GitLab web interface |
| `HTTP2HTTPS` | `state/environment` | Whether Traefik redirects HTTP to HTTPS (`True` / `False`) |
| `LETS_ENCRYPT` | `state/environment` | Whether Traefik requests a Let's Encrypt certificate (`True` / `False`) |
| `GITLAB_NGINX_PORT` | `state/environment` | Allocated local TCP port for GitLab HTTP behind Traefik |
| `GITLAB_REGISTRY_PORT` | `state/environment` | Allocated local TCP port for GitLab Container Registry behind Traefik |
| `GITLAB_SSH_PORT` | `state/environment` | Allocated public TCP port for Git over SSH (opened in node firewall) |
| `GITLAB_REGISTRY_HOST` | `state/environment` | Optional FQDN for the integrated Container Registry |
| `LDAP_DOMAIN` | `state/environment` | Optional NethServer 8 user domain name bound via `Ldapproxy` |
| `RUNNER_ENABLED` | `state/environment` | Enables or disables the integrated GitLab Runner (`True` / `False`) |
| `GITLAB_INITIAL_PASSWORD` | `state/passwords.env` | Initial/configured password for the `root` administrator account (mode `0600`) |

### Maintenance, Backup & Restore

- **Pre-Backup Hook (`imageroot/bin/module-dump-state`):** Automatically invoked by NS8 `run-backup` before Restic snapshots the module volumes. When `gitlab-app` is active and bootstrapped, it runs `gitlab-backup create SKIP=repositories,uploads,builds,artifacts,lfs,terraform_state,ci_secure_files,pages,registry,packages CRON=1` to write a consistent hot PostgreSQL database dump into `/var/opt/gitlab/backups/` without duplicating large repository or registry blobs already covered by `volumes/gitlab-data`.
- **Post-Backup Hook (`imageroot/bin/module-cleanup-state`):** Removes temporary `/var/opt/gitlab/backups/*_gitlab_backup.tar` archives after the Restic snapshot finishes.
- **Database Restore (`imageroot/actions/restore-module/40restoreDB`):** After Restic restores the volumes in `10restore`, `40restoreDB` launches an ephemeral `${GITLAB_CE_IMAGE}` container, starts the embedded PostgreSQL service, and runs `gitlab-backup restore` against the backup archive in `/var/opt/gitlab/backups/` before `50configure` re-applies routes, firewall rules, and starts the services.

---

## Update Module via CLI

Updates are normally applied through the **NethServer 8 Software Center UI**. To manually update via CLI:

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/bls-isp/gitlab:1.0.5","instances":["gitlab1"]}'
```

---

## Publishing a New Release (Semantic Versioning)

In accordance with NethServer 8 standards, releases must use pure **Semantic Versioning (`X.Y.Z`) without a `v` prefix** (e.g. `1.0.5`, `1.1.0`, or `1.1.0-testing.1` for pre-releases):

```bash
git tag -a 1.0.5 -m "Release 1.0.5"
git push origin main --tags
```

The GitHub Actions workflow (`.github/workflows/publish-images.yml`) automatically builds and publishes `ghcr.io/bls-isp/gitlab:1.0.5` and updates `repodata.json` on the `repomd` branch.

---

## Uninstall

To uninstall the instance and remove its data:

```bash
remove-module --no-preserve gitlab1
```

---

## Testing

Test the module using the `test-module.sh` script:

```bash
./test-module.sh <NODE_ADDR> ghcr.io/bls-isp/gitlab:1.0.5
```

---

## Data Privacy & Terms

This module runs **100% self-hosted** on your NethServer 8 cluster:

- **No External Telemetry:** All Git repositories, CI/CD artifacts, container images, issues, and user credentials remain exclusively on your NethServer 8 node inside the rootless module volumes (`gitlab-data`, `gitlab-config`, `gitlab-runner-config`). Usage ping and Puma/Sidekiq Prometheus exporters are disabled by default to minimize footprint and prevent unwanted telemetry.
- **Terms & License:** Distributed under the **GNU General Public License v3.0 or later (`GPL-3.0-or-later`)** without warranty of any kind. See [`LICENSE`](LICENSE) for full details.

---

## Limitations, Roadmap & Contact

- **Hardware Requirements:** GitLab CE Omnibus bundles PostgreSQL, Gitaly, Redis, Puma, Sidekiq, and Workhorse. While tuned for lower memory consumption (~2.5–3 GB RAM idle), at least **4 GB of free RAM** and **2–4 CPU cores** are recommended on the target NS8 node.
- **Bug Reports & Feature Requests:** Please open an issue on [GitHub Issues](https://github.com/BLS-ISP/NS8-GitLab/issues).
- **Maintainer Contact:** BLS-ISP (`info@bls-isp.de`) or via the [NethServer Community Forum](https://community.nethserver.org/).
