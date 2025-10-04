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
        compose_stack_type: "demo"
        compose_stack_name: "myapp"
        compose_stack_domain: "example.lan"
        compose_stack_state: "present"
```

## Variables

**Required:**
- `compose_stack_type` - Stack type to deploy (determines which template/vars to use, e.g., `"demo"`, `"grafana"`)
- `compose_stack_name` - Deployment instance identifier (allows multiple deployments of same type, e.g., `"grafana-dev"`, `"grafana-prd"`)
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

- `demo` - Basic nginx demo application
- `grafana` - Grafana + InfluxDB monitoring stack

**Note:** Stack configurations are defined in `vars/{{ compose_stack_type }}.yml` and are not user-modifiable. Some stacks may expose minimal configuration options via `defaults/{{ compose_stack_type }}.yml` when `stack_meta.has_user_vars: true`.

## Usage Examples

### Deploy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "demo"
        compose_stack_name: "demo"
        compose_stack_domain: "example.lan"
```

### Destroy Stack

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "demo"
        compose_stack_name: "demo"
        compose_stack_state: "absent"
```

### Deploy Multiple Stacks

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "demo"
        compose_stack_name: "demo"
        compose_stack_domain: "example.lan"

    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana"
        compose_stack_domain: "example.lan"
```

### Deploy Multiple Instances of Same Stack Type

```yaml
- hosts: docker_hosts
  roles:
    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana-dev"
        compose_stack_domain: "dev.example.lan"

    - role: cloudnonsense.compose_stack
      vars:
        compose_stack_type: "grafana"
        compose_stack_name: "grafana-prd"
        compose_stack_domain: "prd.example.lan"
```

## Architecture

The role uses a declarative, template-based approach:

- **Opinionated Stack Definitions** (`vars/{{ compose_stack_type }}.yml`) - Pre-configured services, networks, volumes, and all compose settings
- **Universal Template** (`templates/compose.yml.j2`) - Renders any stack definition using modular includes
- **Minimal User Input** - Users specify stack type, instance name, and optional domain; the role handles the rest
- **External Networks** - Networks must be created externally before deploying stacks

## Testing

Molecule tests are organized per-stack with a test-all helper script:

```bash
# Test all stacks (using helper script)
./test-all-scenarios.sh

# Test all stacks (manual)
molecule test -s demo && molecule test -s grafana

# Test individual stack
molecule test -s demo

# Development workflow
molecule converge -s demo
molecule verify -s demo
```

## License

MIT

## Author

[CloudNonsense.com](https://cloudnonsense.com)
