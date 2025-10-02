# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible role (`cloudnonsense.compose_stack`) for managing Docker Compose v2 stacks with a declarative, template-based approach. The role provides lifecycle management (deploy/update/destroy) for Docker Compose applications.

## Architecture

### Core Workflow

The role follows a strict execution flow in tasks/main.yml:
1. **Validate** - Check all required variables (tasks/validate.yml)
2. **Load Per-Stack Variables** - Auto-include `defaults/{{ stack.name }}.yml`
3. **Execute State** - Run create.yml or destroy.yml based on `stack.state`

### Template System

The role uses a two-layer configuration pattern:

1. **Core Stack Config** (`defaults/main.yml`) - Defines individual `compose_stack_*` variables which are automatically composed into a `stack` dictionary for internal use
2. **Per-Stack Services** (`defaults/{{ stack.name }}.yml`) - Defines the `services` dictionary with container-specific config and a `networks` list specifying which networks the stack requires (networks must be created externally)

Templates in `templates/{{ stack.name }}/compose.yml.j2` reference both dictionaries and use modular includes from `templates/includes/` for reusable blocks (service_common, service_ports, service_labels, service_networks, service_configs, networks, configs, etc.).

**Important Pattern**: Templates set a local variable referencing the service config, e.g.:
```jinja2
{% set svc = services.nginxdemo %}
```
Then include modular templates that reference `svc` for that service's configuration.

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

1. Create `defaults/{{ stack_name }}.yml` with:
   - `networks` list - Networks required by this stack (must be created externally)
   - `services` dictionary - Container configurations
2. Create `templates/{{ stack_name }}/compose.yml.j2` using standard includes
3. Use the existing pattern: `{% set svc = services.servicename %}` then include modular templates
4. Create new Molecule scenario directory `molecule/{{ stack_name }}/`:
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

- Reusable logic belongs in `templates/includes/*.j2`
- Stack-specific templates in `templates/{{ stack_name }}/`
- Always reference `svc` variable for service config (set via `{% set svc = services.servicename %}`)

## Key Variables

Users configure the role using individual `compose_stack_*` variables:

**Required Core Variables**:
- `compose_stack_name` - Stack identifier
- `compose_stack_state` - "present" or "absent"

**Optional Configuration**:
- `compose_stack_domain` - Domain name for the stack
- `compose_stack_base_dir` - Base directory (default: "/opt/apps")
- `compose_stack_dst_dir` - Destination directory (default: "{{ compose_stack_base_dir }}/{{ compose_stack_name }}")
- `compose_stack_file_*` - File ownership and permissions
- `compose_stack_dir_mode` - Directory permissions
- `compose_stack_destroy_remove_volumes` - Remove volumes on destroy (default: true)
- `compose_stack_destroy_remove_images` - Remove images on destroy: "all" or "local" (default: "local")

**Internal Implementation**:
The role automatically builds a `stack` dictionary from these individual variables in `defaults/main.yml`. This internal dict is what tasks and templates reference (e.g., `{{ stack.name }}`, `{{ stack.domain }}`). Users never need to construct this dict manually.

**Auto-Loaded from Per-Stack Var Files** (`defaults/{{ compose_stack_name }}.yml`):
- `services` dictionary - Container configurations
- `networks` list - Networks required by the stack (must be created externally before deploying the stack)

## Requirements

- Ansible ≥ 2.12
- Docker Engine with Compose v2 plugin
- Ansible collection: `community.docker`
- Python docker library on target hosts
