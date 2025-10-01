# Ansible Role: compose-stack

An Ansible role for managing Docker Compose v2 stacks with a consistent, reusable pattern.
Deploy, update, and remove application stacks using Jinja2 templates and declarative configuration.

---

## Features

- **Lifecycle Management**: Deploy, update, or destroy Docker Compose stacks declaratively
- **Template-Based**: Uses Jinja2 templates with reusable includes for DRY compose files
- **Network Management**: Automatically creates and manages Docker networks for each stack
- **Validation**: Built-in variable validation with clear error messages
- **Idempotent**: Safe to run repeatedly, only makes necessary changes
- **Automatic Updates**: Stack automatically updates when compose.yml changes
- **Tested**: Includes comprehensive Molecule tests

---

## Requirements

- **Ansible** ≥ 2.12
- **Docker Engine** installed and running on target hosts
- **Docker Compose v2 plugin** installed
- **Ansible Collection**: `community.docker`
- **Python libraries**: `docker` (on target hosts)

---

## Installation

```bash
ansible-galaxy install cloudnonsense.compose_stack
```

Or add to `requirements.yml`:

```yaml
roles:
  - name: cloudnonsense.compose_stack
```

---

## Role Variables

The role uses individual variables with sensible defaults. All variables are optional except `compose_stack_name` and `compose_stack_state`.

### Core Variables

Default values are defined in [`defaults/main.yml`](defaults/main.yml):

```yaml
compose_stack_name: ""                              # Stack name (required)
compose_stack_state: "present"                      # "present" or "absent"
compose_stack_domain: ""                            # Domain (e.g., "example.lan")
compose_stack_base_dir: "/opt/apps"                 # Base directory for stacks
compose_stack_src_file: "{{ compose_stack_name }}/compose.yml.j2"
compose_stack_dst_dir: "{{ compose_stack_base_dir }}/{{ compose_stack_name }}"

# File/directory permissions
compose_stack_file_owner: "root"
compose_stack_file_mode: "0644"
compose_stack_dir_mode: "0755"

# Networks
compose_stack_networks:
  - { name: "{{ compose_stack_name }}", driver: bridge }

# Destroy options
compose_stack_destroy_remove_volumes: true
compose_stack_destroy_remove_images: "local"        # "all" or "local"
compose_stack_destroy_remove_networks: true
```

### Variable Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `compose_stack_name` | ✅ | `""` | Stack name, used for directories and container naming |
| `compose_stack_state` | ✅ | `"present"` | `"present"` to deploy/update, `"absent"` to destroy |
| `compose_stack_domain` | ❌ | `""` | Domain name (used in Traefik labels, etc.) |
| `compose_stack_base_dir` | ❌ | `"/opt/apps"` | Base directory for all stacks |
| `compose_stack_src_file` | ❌ | `"{{ compose_stack_name }}/compose.yml.j2"` | Template path relative to `templates/` |
| `compose_stack_dst_dir` | ❌ | `"{{ compose_stack_base_dir }}/{{ compose_stack_name }}"` | Destination directory for compose.yml |
| `compose_stack_file_owner` | ❌ | `"root"` | Owner of rendered compose.yml |
| `compose_stack_file_mode` | ❌ | `"0644"` | File permissions for compose.yml |
| `compose_stack_dir_mode` | ❌ | `"0755"` | Directory permissions |
| `compose_stack_networks` | ❌ | See above | List of Docker networks to create |
| `compose_stack_destroy_*` | ❌ | See above | Cleanup options when destroying |

**Note:** The role internally builds a `stack` dictionary from these variables, which is used by templates.

---

## Per-Stack Configuration Pattern

The role automatically loads additional variables from `defaults/{{ stack.name }}.yml` which should define the `services` structure used by your templates.

**Example:** `defaults/nginx-demo.yml`

```yaml
---
services:
  nginxdemo:
    container_name: "nginx-demo"
    image: "ubuntu/nginx:latest"
    restart: "unless-stopped"
    ports:
      - "80:80"
    labels:
      traefik:
        enabled: true
        pattern: "default"
      raw: []
    configs:
      - source: "index.html"
        target: "/var/www/html/index.html"
        mode: "0644"
```

---

## Template Structure

Templates live in `templates/{{ stack.name }}/compose.yml.j2` and can use modular includes.

**Example:** `templates/nginx-demo/compose.yml.j2`

```jinja2
---
{% set svc = services.nginxdemo %}
services:
  "{{ stack.name }}":
{% include "includes/service_common.j2" %}
{% include "includes/service_logging.j2" %}
{% include "includes/service_ports.j2" %}
{% include "includes/service_labels.j2" %}
{% include "includes/service_networks.j2" %}
{% include "includes/service_configs.j2" %}

{% include "includes/networks.j2" %}
{% include "includes/configs.j2" %}
...
```

### Available Template Includes

Located in `templates/includes/`:

- `service_common.j2` - Container name, image, restart policy
- `service_ports.j2` - Port mappings
- `service_networks.j2` - Network attachments
- `service_labels.j2` - Docker labels (including Traefik)
- `service_configs.j2` - Docker configs
- `service_logging.j2` - Logging configuration
- `networks.j2` - Top-level networks definition
- `configs.j2` - Top-level configs definition

---

## Example Usage

### Deploy a Single Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginx-demo"
        compose_stack_domain: "example.lan"
        compose_stack_state: "present"
```

### Deploy Multiple Stacks

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginx-demo"
        compose_stack_domain: "example.lan"

    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "grafana"
        compose_stack_domain: "example.lan"
```

### Custom Configuration

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "myapp"
        compose_stack_domain: "myapp.example.com"
        compose_stack_state: "present"
        compose_stack_base_dir: "/srv/docker"
        compose_stack_networks:
          - { name: "myapp-frontend", driver: bridge }
          - { name: "myapp-backend", driver: bridge }
```

### Destroy a Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginx-demo"
        compose_stack_state: "absent"
        compose_stack_destroy_remove_volumes: true      # Delete volumes
        compose_stack_destroy_remove_images: "local"    # Remove locally built images
        compose_stack_destroy_remove_networks: true     # Delete networks
```

### Destroy Without Removing Data

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "grafana"
        compose_stack_state: "absent"
        compose_stack_destroy_remove_volumes: false     # Preserve data volumes
        compose_stack_destroy_remove_images: "none"     # Keep images
        compose_stack_destroy_remove_networks: false    # Keep networks
```

---

## Directory Structure

When deployed, stacks create the following structure:

```
/opt/apps/                    # stack.base_dir
  ├── nginx-demo/             # stack.name
  │   └── compose.yml         # Rendered from template
  └── grafana/
      └── compose.yml
```

---

## Tasks Overview

The role performs these tasks in order:

1. **Validate** - Check all required variables are present and valid
2. **Load Per-Stack Defaults** - Include `defaults/{{ stack.name }}.yml`
3. **Create or Destroy** - Based on `stack.state`:

### When `state: present`
- Create Docker networks (if defined)
- Create application directory
- Render compose.yml template
- Start/update Docker Compose stack

### When `state: absent`
- Check if stack directory exists
- Stop and remove containers
- Remove application directory
- Remove Docker networks (if `destroy.remove_networks: true`)

---

## Testing

The role includes Molecule tests organized into separate scenarios - one per stack type.

### Test Scenarios

| Scenario | Stacks Tested | Purpose |
|----------|---------------|---------|
| `nginx-demo` | nginx-demo only | Test nginx-demo stack in isolation |
| `grafana` | grafana + influxdb | Test grafana stack in isolation |

**Note**: The `molecule/default/` directory contains only shared resources (Dockerfile.j2). Each stack must be tested via its own scenario.

### Running Tests

```bash
# Run all stack tests sequentially
molecule test -s nginx-demo && molecule test -s grafana

# Test individual stacks (fast iteration during development)
molecule test -s nginx-demo
molecule test -s grafana

# Development workflow - quick deploy and verify
molecule converge -s nginx-demo
molecule verify -s nginx-demo

# Test individual phases for a specific stack
molecule converge -s nginx-demo    # Deploy nginx-demo
molecule verify -s nginx-demo      # Run verification tests
molecule idempotence -s nginx-demo # Verify no changes on re-run
molecule destroy -s nginx-demo     # Clean up

# Run tests in parallel (optional)
molecule test -s nginx-demo & molecule test -s grafana & wait
```

### What's Tested

Each scenario verifies:
- Stack deployment and service availability
- HTTP response from deployed services (nginx :37080, grafana :37005, influxdb :8086)
- Docker network creation and configuration
- Compose stack status via `docker compose ps`
- Proper cleanup when destroying stacks
- Idempotence (running twice produces no changes)

**Tip**: Each stack takes ~30s to test in isolation. Test only the stack you're working on for fastest feedback.

---

## Troubleshooting

### "Template file not found" Error

Ensure:
1. Template exists at `templates/{{ stack.src_file }}`
2. `stack.src_file` is correctly set
3. Per-stack defaults file exists at `defaults/{{ stack.name }}.yml`

### "undefined variable" in Template

Check that `defaults/{{ stack.name }}.yml` defines all variables your template references (typically the `services` dictionary).

### Network Already Exists

If a network already exists externally, either:
- Set `stack.networks: []` to skip network creation
- Use a different network name
- (Future) Use external network support

---

## Limitations

- Networks are always created; external network support is planned
- Network deletion doesn't check if other containers use the network
- No built-in backup/restore for volumes

---

## Roadmap

- [ ] Support for external networks (`external: true`)
- [ ] Better network cleanup (check for usage before deletion)
- [ ] Volume backup/restore functionality
- [ ] Support for Docker secrets
- [ ] Configurable wait/health checks after deployment

---

## License

MIT

---

## Author

**cloudnonsense.compose_stack** role by [CloudNonsense.com](https://cloudnonsense.com)
