# ns8-gitlab

[GitLab Community Edition](https://about.gitlab.com/) module for **NethServer 8 (NS8)**.

- **GitHub Repository:** [`https://github.com/BLS-ISP/NS8-GitLab`](https://github.com/BLS-ISP/NS8-GitLab)
- **Container Image:** `ghcr.io/bls-isp/gitlab`
- **NS8 Software Center Repository URL:** `https://raw.githubusercontent.com/BLS-ISP/NS8-GitLab/repomd/`

---

## Features

- **GitLab CE (`19.5.0-ce.0`)** running in a rootless Podman pod behind the NS8 Traefik reverse proxy
- **Let's Encrypt & HTTP-to-HTTPS redirect** configurable via the NS8 Web UI
- **NS8 LDAP / Active Directory integration** (automatic user authentication via NS8 user domains and `Ldapproxy`, including `user-domain-changed` event handler)
- **NS8 Smarthost / SMTP integration** (automatic discovery and reload on `smarthost-changed` events)
- **Git over SSH** (automatically allocates a dedicated TCP port, opens it in the NS8 node firewall via `node:fwadm`, and configures `gitlab_shell_ssh_port`)
- **Integrated GitLab Container Registry** (optional, exposed on a separate FQDN via Traefik)
- **Integrated GitLab Runner (`v19.5.0`)** (optional toggle in UI; enables `podman.socket` and automatically registers the instance runner in the background using the `glrt-` runner authentication token workflow once GitLab is ready)
- **Backup, Restore & Clone/Move** (`restore-module`, `clone-module`, and `update-module` support)

---

## Install via NethServer 8 Software Center UI (Recommended)

1. Open the **NethServer 8 Cluster Admin UI**.
2. Go to **Software center → Settings → Software repositories → Add repository**.
3. Enter the following details:
   - **Name:** `bls-isp`
   - **URL:** `https://raw.githubusercontent.com/BLS-ISP/NS8-GitLab/repomd/`
   - **Status:** Enabled
4. Open **Software center**, find **GitLab**, and click **Install**.
5. Future module updates published with a newer Semantic Version tag (e.g. `1.0.1`, `1.1.0`) will automatically appear in the **Software center → Updates** view.

> **Tip:** To clear the 1-hour repository metadata cache on NS8 and immediately see a newly published release:
> ```bash
> redis-cli del cluster/repository_cache/bls-isp
> ```

---

## Install via CLI

Instantiate the module using a **Semantic Version tag** (do not use `:latest` in production, as NS8 skips UI updates for `:latest` development instances):

```bash
add-module ghcr.io/bls-isp/gitlab:1.0.0 1
```

The output of the command will return the instance name:

```json
{"module_id": "gitlab1", "image_name": "gitlab", "image_url": "ghcr.io/bls-isp/gitlab:1.0.0"}
```

---

## Configure

Assuming the instance is named `gitlab1`, you can configure it directly in the **NethServer 8 Web UI** (**Settings → gitlab1**) or via CLI using `configure-module`:

- `host`: Fully qualified domain name for the GitLab web interface (e.g. `git.example.org`)
- `http2https`: Redirect HTTP requests to HTTPS (`true` / `false`)
- `lets_encrypt`: Request a valid Let's Encrypt certificate (`true` / `false`)
- `password`: Initial password for the `root` user (optional, minimum 8 characters)
- `ldap_domain`: NS8 LDAP / Active Directory domain for user authentication (optional)
- `registry_host`: Fully qualified domain name for the GitLab Container Registry (optional, e.g. `registry.example.org`)
- `runner_enabled`: Enable and auto-register the integrated GitLab Runner container (`true` / `false`)

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

## Update Module via CLI

Updates are normally applied through the **NethServer 8 Software Center UI**. To manually update via CLI:

```bash
api-cli run update-module --data '{"module_url":"ghcr.io/bls-isp/gitlab:1.0.1","instances":["gitlab1"]}'
```

---

## Publishing a New Release (Semantic Versioning)

In accordance with NethServer 8 standards, releases must use pure **Semantic Versioning (`X.Y.Z`) without a `v` prefix** (e.g. `1.0.0`, `1.0.1`, or `1.0.2-testing.1` for pre-releases):

```bash
git tag -a 1.0.1 -m "Release 1.0.1"
git push origin main --tags
```

The GitHub Actions workflow (`.github/workflows/publish-images.yml`) automatically builds and publishes `ghcr.io/bls-isp/gitlab:1.0.1` and updates `repodata.json` on the `repomd` branch.

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
./test-module.sh <NODE_ADDR> ghcr.io/bls-isp/gitlab:1.0.0
```
