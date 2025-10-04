# Ansible Role: compose-stack

Ansible role for managing Docker Compose v2 stacks with opinionated, pre-configured stack definitions. Deploy production-ready compose stacks with minimal configuration.

## Requirements

- Ansible ≥ 2.12
- Docker Engine with Compose v2 plugin
- Ansible collection: `community.docker`
- Python `docker` library on target hosts

## Installation

```bash
ansible-galaxy install cloudnonsense.compose_stack
```

## Quick Start

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "myapp"
        compose_stack_domain: "example.lan"
        compose_stack_state: "present"
```

## Variables

**Required:**
- `compose_stack_name` - Stack identifier
- `compose_stack_state` - `"present"` or `"absent"`

**Optional:**
- `compose_stack_domain` - Domain name (default: `""`)
- `compose_stack_base_dir` - Base directory (default: `"/opt/apps"`)
- `compose_stack_file_owner` - File owner (default: `"root"`)
- `compose_stack_file_mode` - File permissions (default: `"0644"`)
- `compose_stack_dir_mode` - Directory permissions (default: `"0755"`)
- `compose_stack_destroy_remove_volumes` - Remove volumes on destroy (default: `true`)
- `compose_stack_destroy_remove_images` - Remove images on destroy: `"all"` or `"local"` (default: `"local"`)

**Available Stacks:**

Each stack comes with pre-configured, opinionated settings. Stacks are consumed "as-is" with minimal user input:

- `nginxdemo` - Basic nginx demo application
- `grafana` - Grafana + InfluxDB monitoring stack

**Note:** Stack configurations are defined in `vars/{{ stack_name }}.yml` and are not user-modifiable. Some stacks may expose minimal configuration options via `defaults/{{ stack_name }}.yml` when `stack_meta.has_user_vars: true`.

## Usage Examples

### Deploy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginxdemo"
        compose_stack_domain: "example.lan"
```

### Destroy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginxdemo"
        compose_stack_state: "absent"
```

### Deploy Multiple Stacks

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "nginxdemo"
        compose_stack_domain: "example.lan"

    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_name: "grafana"
        compose_stack_domain: "example.lan"
```

## Architecture

The role uses a declarative, template-based approach:

- **Opinionated Stack Definitions** (`vars/{{ stack_name }}.yml`) - Pre-configured services, networks, volumes, and all compose settings
- **Universal Template** (`templates/compose.yml.j2`) - Renders any stack definition using modular includes
- **Minimal User Input** - Users specify stack name and optional domain; the role handles the rest
- **External Networks** - Networks must be created externally before deploying stacks

## Testing

Molecule tests are organized per-stack with a test-all helper script:

```bash
# Test all stacks (using helper script)
./test-all-scenarios.sh

# Test all stacks (manual)
molecule test -s nginxdemo && molecule test -s grafana

# Test individual stack
molecule test -s nginxdemo

# Development workflow
molecule converge -s nginxdemo
molecule verify -s nginxdemo
```

## License

MIT

## Author

[CloudNonsense.com](https://cloudnonsense.com)
