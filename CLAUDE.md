# CLAUDE.md

Guidance for Claude Code when working with this Ansible role for managing Docker Compose v2 stacks.

## Architecture

**Workflow**: tasks/main.yml → Validate → Load vars/{{ stack.type }}.yml → Execute create.yml or destroy.yml

**Configuration Pattern**:
- `defaults/main.yml` - User-facing `compose_stack_*` variables → auto-composed into `stack` dict in `vars/main.yml`
- `vars/{{ stack.type }}.yml` - Opinionated stack definitions (services, volumes, commands, etc.). NOT user-modifiable.
- Networks auto-generated: primary = `{{ stack.name }}`, optional additional via `compose_stack_additional_networks`

**Template System**:
- Universal template `templates/compose.yml.j2` loops over `services` list
- Modular includes in `templates/includes/*.j2` (service_common, service_networks, networks, etc.)
- Service properties accessed via `svc_data` loop variable

## Key Variables

**Required**: `compose_stack_type`, `compose_stack_name`, `compose_stack_state`

**Optional**: `compose_stack_domain`, `compose_stack_additional_networks`, `compose_stack_base_dir`, `compose_stack_restart_policy`, file/dir ownership/permissions, destroy options

**Internal**: User vars auto-compose into `stack` dict (stack.type, stack.name, stack.domain, stack.additional_networks, etc.)

**Networks**: Auto-generated as `[stack.name] + stack.additional_networks`. Must be created externally before stack deployment.

## Testing

**Pattern**: Separate Molecule scenarios per stack (demo, grafana). No `molecule/default/` scenario.

**Helper script**:
```bash
./test-all-scenarios.sh              # Run 'molecule test' on all
./test-all-scenarios.sh converge     # Run 'molecule converge' on all
./test-all-scenarios.sh verify       # etc.
```

**Individual stack**:
```bash
molecule test -s demo
molecule converge -s demo && molecule verify -s demo  # Fast iteration
```

**Test structure per scenario**:
- `molecule.yml` - Uses `../default/Dockerfile.j2`, enables prepare playbook
- `prepare.yml` - Create networks (primary: `{{ stack.name }}`, additional test networks)
- `converge.yml` - Deploy stack (set `compose_stack_additional_networks` if testing)
- `verify.yml` - Stack-specific tests
- `cleanup.yml` - Teardown

## Adding a New Stack

1. Create `vars/{{ stack_type }}.yml`:
   - `stack_meta: { has_user_vars: false }` (or true if step 2 needed)
   - `services` list with `{{ stack.name }}-<service>` naming pattern
   - All hardcoded settings (volumes, commands, environment, etc.)
   - No networks list (auto-generated)

2. (Optional) If user vars needed: `defaults/{{ stack_type }}.yml` + set `has_user_vars: true`

3. (Optional) Custom templates: `templates/{{ stack_type }}/`

4. Create `molecule/{{ stack_type }}/` with molecule.yml, prepare.yml, converge.yml, verify.yml, cleanup.yml

## Development Notes

- Validation: Add to tasks/validate.yml with clear fail_msg
- Templates: Universal template handles all stacks. Stack-specific assets go in `templates/{{ stack_type }}/`
- Stacks are opinionated "as-is". Modified versions = new stack variants in the role.
- External networks required: Networks must exist before deployment

## Requirements

Ansible ≥ 2.12, Docker Engine + Compose v2, community.docker collection, Python docker library
