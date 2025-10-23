# Ansible Role: compose-stack

Manage Docker Compose v2 stacks with opinionated, pre-configured definitions.

## Requirements

Ansible ≥ 2.12, Docker Engine + Compose v2, `community.docker` collection, Python `docker` library

## Installation

```bash
ansible-galaxy install cloudnonsense.compose_stack
```

## Usage

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "demo"
        compose_stack_name: "myapp"
        compose_stack_state: "present"
```

**Required vars:** `compose_stack_type`, `compose_stack_name`, `compose_stack_state` (`present`/`absent`)

**Optional:**
- `compose_stack_domain` - Domain for Traefik labels
- `compose_stack_additional_networks` - Extra networks to attach (must exist externally)
- `compose_stack_base_dir` - Base directory for stack files (default: `/opt/apps`)
- `compose_stack_restart_policy` - Default restart policy (default: `always`)
- `compose_stack_config` - Stack-specific configuration (see per-stack requirements)
- `compose_stack_file_owner`, `compose_stack_file_group` - File ownership (default: `root`)
- `compose_stack_file_mode`, `compose_stack_dir_mode` - Permissions (default: `0644`/`0755`)
- `compose_stack_env_file_mode` - Permissions for .env files (default: `0600`)
- `compose_stack_destroy_remove_volumes` - Remove volumes on destroy (default: `true`)
- `compose_stack_destroy_remove_images` - Remove images on destroy (default: `local`, options: `all`/`local`)

## Stacks

### `demo`
Nginx web server for testing.

**Requirements:** None

---

### `grafana`
Grafana + InfluxDB + Telegraf + Prometheus monitoring stack with pre-configured dashboards.

**Requirements:**
```yaml
compose_stack_config:
  influxdb:
    database: "monitoring"
    admin_user: "admin"
    admin_password: "secure_password"
  grafana:
    admin_user: "admin"
    admin_password: "secure_password"
```

**Includes:**
- Grafana (port 37011) with provisioned datasources and dashboards
- InfluxDB 1.8 (port 37012) for time-series data
- Telegraf for metrics collection
- Prometheus (port 37013) for additional metrics

---

### `traefik`
Traefik v3 reverse proxy with TLS support and Docker integration.

**Requirements:**
- Traefik configuration files in `templates/traefik/`:
  - `traefik.yaml` - Main Traefik configuration
  - `tls.yml` - TLS configuration
  - `cert.crt` and `cert.key` - TLS certificates

**Features:**
- Ports: 80 (HTTP), 443 (HTTPS), 8080 (Dashboard)
- Docker socket access for container discovery
- Pre-configured with TLS certificates

---

### `actions-runner`
Self-hosted GitHub Actions runner with Docker build support.

**Requirements:**
```yaml
compose_stack_config:
  github_runner:
    github_organization: "your-org"
    github_access_token: "ghp_xxxxx"
    runner_name: "runner-name"
    runner_labels: "self-hosted,linux,x64"  # Optional, defaults shown
```

**Features:**
- Custom build context with Dockerfile support
- Automatic runner registration
- Docker-in-Docker capability for builds

## Per-Service Overrides

Override default image or restart policy for specific services:

```yaml
compose_stack_config:
  <service>:
    image: "custom/image:tag"    # Override default image
    restart: "on-failure"        # Override restart policy for this service
```

**Example:**
```yaml
compose_stack_config:
  grafana:
    image: "grafana/grafana-enterprise:11.5.1"
    restart: "unless-stopped"
```

## Environment Variables

Service environment variables are automatically extracted to `.env` files with restrictive permissions (`0600` by default). This enhances security by isolating credentials and secrets from the main compose file.

## License

MIT | [CloudNonsense.com](https://cloudnonsense.com)
