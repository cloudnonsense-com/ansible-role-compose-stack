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

### Core Stack Configuration

The role uses a single `stack` dictionary variable. Default values are defined in [`defaults/main.yml`](defaults/main.yml):

```yaml
stack:
  name: ""                  # Stack name (required)
  state: "present"          # "present" to deploy, "absent" to destroy
  domain: ""                # Domain for the stack (e.g., "example.lan")

  base_dir: "/opt/apps"
  src_file: "{{ stack.name }}/compose.yml.j2"
  dst_dir: "{{ stack.base_dir }}/{{ stack.name }}"

  file:
    owner: "root"
    mode: "0644"

  dir:
    mode: "0755"

  networks:
    - { name: "{{ stack.name }}", driver: bridge }

  destroy:
    remove_volumes: true
    remove_images: "local"      # "all" or "local"
    remove_networks: true
```

### Variable Reference

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `stack.name` | string | ✅ | `""` | Stack name, used for directories and container naming |
| `stack.state` | string | ✅ | `"present"` | `"present"` to deploy/update, `"absent"` to destroy |
| `stack.domain` | string | ❌ | `""` | Domain name for the stack (used in Traefik labels, etc.) |
| `stack.base_dir` | string | ✅ | `"/opt/apps"` | Base directory for all stacks |
| `stack.src_file` | string | ✅ | `"{{ stack.name }}/compose.yml.j2"` | Template path relative to `templates/` |
| `stack.dst_dir` | string | ✅ | `"{{ stack.base_dir }}/{{ stack.name }}"` | Destination directory for rendered compose.yml |
| `stack.file.mode` | string | ✅ | `"0644"` | File permissions for compose.yml |
| `stack.dir.mode` | string | ✅ | `"0755"` | Directory permissions |
| `stack.networks` | list | ❌ | See above | List of Docker networks to create |
| `stack.destroy.*` | dict | ✅ (when state=absent) | See above | Cleanup options when destroying |

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
        stack:
          name: "nginx-demo"
          domain: "example.lan"
          state: "present"
```

### Deploy Multiple Stacks

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        stack:
          name: "nginx-demo"
          domain: "example.lan"
          state: "present"

    - role: cloudnonsense.compose_stack
      vars:
        stack:
          name: "grafana"
          domain: "example.lan"
          state: "present"
```

### Custom Configuration

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        stack:
          name: "myapp"
          domain: "myapp.example.com"
          state: "present"
          base_dir: "/srv/docker"
          src_file: "myapp/compose.yml.j2"
          networks:
            - { name: "myapp-frontend", driver: bridge }
            - { name: "myapp-backend", driver: bridge }
```

### Destroy a Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        stack:
          name: "nginx-demo"
          state: "absent"
          destroy:
            remove_volumes: true      # Delete volumes
            remove_images: "local"    # Remove locally built images
            remove_networks: true     # Delete networks
```

### Destroy Without Removing Data

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        stack:
          name: "grafana"
          state: "absent"
          destroy:
            remove_volumes: false     # Preserve data volumes
            remove_images: "none"     # Keep images
            remove_networks: false    # Keep networks
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

The role includes Molecule tests in `molecule/default/`:

```bash
# Run all tests
molecule test

# Test specific scenarios
molecule converge    # Deploy stacks
molecule verify      # Run verification tests
molecule destroy     # Clean up
```

Tests verify:
- Stack deployment and service availability
- HTTP response from deployed services
- Network creation and connectivity
- Proper cleanup when destroying stacks
- Idempotence (running twice produces no changes)

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
