# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible role (`cloudnonsense.compose_stack`) for managing Docker Compose v2 stacks with a declarative, template-based approach. The role provides lifecycle management (deploy/update/destroy) for Docker Compose applications.

## Architecture

### Core Workflow

The role follows a strict execution flow in tasks/main.yml:
1. **Validate** - Check all required variables (tasks/validate.yml)
2. **Load Per-Stack Variables** - Auto-include `vars/{{ stack.name }}.yml`
3. **Execute State** - Run create.yml or destroy.yml based on `stack.state`

### Template System

The role uses a two-layer configuration pattern:

1. **Core Stack Config** (`defaults/main.yml`) - Defines individual `compose_stack_*` variables which are automatically composed into a `stack` dictionary (in `vars/main.yml`) for internal use
2. **Per-Stack Definitions** (`vars/{{ stack.name }}.yml`) - Opinionated, pre-configured stack definitions with hardcoded settings for `services`, `networks`, `volumes`, `commands`, `environment`, and all other compose-related configuration. These are NOT user-modifiable and represent the canonical "as-is" configuration for each stack.

The **universal template** at `templates/compose.yml.j2` iterates over the `services` dictionary and uses modular includes from `templates/includes/` for reusable blocks (service_common, service_logging, service_ports, service_labels, service_networks, service_configs, networks, configs).

**Template Pattern**: The main template uses a for loop to iterate over all services:
```jinja2
{% for svc_name, svc_data in services.items() %}
  {{ svc_name }}:
{% include "includes/service_common.j2" %}
{% include "includes/service_logging.j2" %}
{% include "includes/service_ports.j2" %}
{% include "includes/service_labels.j2" %}
{% include "includes/service_networks.j2" %}
{% include "includes/service_configs.j2" %}
{% endfor %}
{% include "includes/networks.j2" %}
{% include "includes/configs.j2" %}
```

The include templates access service properties through the loop variables `svc_name` and `svc_data`.

### Task Organization

- **tasks/validate.yml** - Multi-stage validation using `assert` modules:
  - Core variable existence and types
  - State-specific variable validation (present vs absent)
  - Template file existence check

- **tasks/create.yml** - Deployment tasks:
  - Create stack directory
  - Render compose.yml from Jinja2 template
  - Start/update stack via `community.docker.docker_compose_v2`

- **tasks/destroy.yml** - Cleanup tasks:
  - Check directory existence first
  - Stop compose stack with configurable cleanup (images/volumes)
  - Remove stack directory

## Testing

Uses Molecule for integration testing with per-stack scenarios.

### Test Commands

The role uses separate Molecule scenarios - one per stack type:
- `nginxdemo` - Tests only nginxdemo stack
- `grafana` - Tests only grafana stack

**Note**: `molecule/default/` contains only shared resources (Dockerfile.j2), not a runnable scenario.

```bash
# Test all stacks sequentially
molecule test -s nginxdemo && molecule test -s grafana

# Test individual stacks (use during development)
molecule test -s nginxdemo
molecule test -s grafana

# Individual phases (must specify scenario)
molecule create -s nginxdemo     # Build test container
molecule converge -s nginxdemo   # Deploy nginxdemo stack
molecule idempotence -s nginxdemo # Verify no changes on re-run
molecule verify -s nginxdemo     # Run verification tests
molecule destroy -s nginxdemo    # Cleanup

# Development workflow (fast iteration on single stack)
molecule converge -s nginxdemo && molecule verify -s nginxdemo

# Parallel testing (optional)
molecule test -s nginxdemo & molecule test -s grafana & wait
```

### Test Environment

- **Driver**: Docker
- **Image**: geerlingguy/docker-ubuntu2204-ansible:latest
- **Privileged**: Required for Docker-in-Docker
- **Volumes**: Mounts Docker socket and cgroup

### What's Tested

The verify.yml playbook tests:
- HTTP responses from deployed services (nginx on :37080, grafana on :37005, influxdb on :8086)
- Compose stack status via `docker compose ps`
- Service availability and expected content

**Note**: Docker networks are created during the prepare phase of testing (before converge), not by the role itself.

## Development Patterns

### Adding a New Stack

1. Create `vars/{{ stack_name }}.yml` with opinionated, static configuration:
   - `stack_meta` dictionary with `has_user_vars: false` flag (set to `true` if step 2 applies)
   - `networks` list - Networks required by this stack (must be created externally)
   - `services` dictionary - Container configurations with keys matching service names
   - All hardcoded settings: volumes, commands, environment variables, etc.
2. (Optional) If minimal user configuration is needed:
   - Set `stack_meta.has_user_vars: true` in `vars/{{ stack_name }}.yml`
   - Create `defaults/{{ stack_name }}.yml` to expose ONLY those specific variables (e.g., selecting from pre-defined dashboards)
   - The role will auto-load this file when `stack_meta.has_user_vars` is `true`
   - Principle: users consume stacks "as-is" with minimal inputs. Modified versions = new stack variants in the role.
3. The universal template at `templates/compose.yml.j2` will automatically render all services - no per-stack template needed
4. If custom templates are needed (e.g., config files), create `templates/{{ stack_name }}/` directory with those files
5. Create new Molecule scenario directory `molecule/{{ stack_name }}/`:
   - `molecule.yml` - Use `dockerfile: ../default/Dockerfile.j2` (relative path), enable `prepare` playbook
   - `prepare.yml` - Create Docker networks required by the stack
   - `converge.yml` - Deploy only this stack
   - `verify.yml` - Tests specific to this stack
   - `cleanup.yml` - Teardown for this stack

### Testing Pattern

The role organizes Molecule tests into **separate scenarios - one per stack type**:

**Key principles:**
- Each stack has its own isolated scenario (see nginxdemo or grafana as examples)
- `molecule/default/` contains only shared resources (Dockerfile.j2), not a runnable scenario
- No test duplication - each stack's tests exist in exactly one place
- Test only what you're working on for fast iteration (~30s per stack)
- Run all scenarios sequentially before commits: `molecule test -s nginxdemo && molecule test -s grafana`

**Why this pattern:**
- **Zero duplication** - Single source of truth for each stack's tests
- **No drift risk** - Impossible for duplicate tests to get out of sync
- **Fast feedback** - Test one stack without waiting for others
- **Clear ownership** - Each scenario owns its stack's test lifecycle

### Variable Validation

When adding new stack variables:
- Add validation to tasks/validate.yml
- Use state-specific validation blocks for present/absent states
- Provide clear fail_msg describing what's required

### Modifying Templates

- **Universal template**: `templates/compose.yml.j2` - Iterates over all services using `{% for svc_name, svc_data in services.items() %}`
- **Reusable includes**: `templates/includes/*.j2` - Common service configuration blocks that reference loop variables
- **Stack-specific assets**: `templates/{{ stack_name }}/` - For custom config files, static assets, etc. (not compose templates)

## Key Variables

Users configure the role using individual `compose_stack_*` variables:

**Required Core Variables**:
- `compose_stack_name` - Stack identifier
- `compose_stack_state` - "present" or "absent"

**Optional Configuration**:
- `compose_stack_domain` - Domain name for the stack (default: "")
- `compose_stack_base_dir` - Base directory (default: "/opt/apps")
- `compose_stack_file_owner` - File ownership (default: "root")
- `compose_stack_file_mode` - File permissions (default: "0644")
- `compose_stack_dir_mode` - Directory permissions (default: "0755")
- `compose_stack_destroy_remove_volumes` - Remove volumes on destroy (default: true)
- `compose_stack_destroy_remove_images` - Remove images on destroy: "all" or "local" (default: "local")

**Internal Implementation**:
The role automatically builds a `stack` dictionary from these individual variables in `vars/main.yml`. This internal dict is what tasks and templates reference (e.g., `{{ stack.name }}`, `{{ stack.domain }}`). Users never need to construct this dict manually.

**Auto-Loaded from Per-Stack Definitions** (`vars/{{ compose_stack_name }}.yml`):
- `stack_meta` dictionary:
  - `has_user_vars` (boolean) - Controls auto-loading of `defaults/{{ compose_stack_name }}.yml`
- `services` dictionary - Pre-configured container definitions
- `networks` list - Networks required by the stack (must be created externally before deploying the stack)
- All stack-specific compose configuration (volumes, commands, environment, etc.)

**Optional Stack-Specific User Variables** (`defaults/{{ compose_stack_name }}.yml`):
- Only created when `stack_meta.has_user_vars: true` in the stack's `vars/` file
- Auto-loaded by the role when the flag is set
- Example: Selecting from pre-defined dashboard options
- Principle: Stacks are opinionated and consumed "as-is" with minimal user input

## Requirements

- Ansible ≥ 2.12
- Docker Engine with Compose v2 plugin
- Ansible collection: `community.docker`
- Python docker library on target hosts
