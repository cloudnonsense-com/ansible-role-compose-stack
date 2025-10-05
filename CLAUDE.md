# CLAUDE.md

Guidance for Claude Code on this Ansible role for Docker Compose v2 stacks.

## Architecture

**Workflow**: Validate → Load `vars/{{ stack.type }}.yml` → Execute create/destroy

**Config**: `compose_stack_*` vars (defaults/main.yml) → `stack` dict (vars/main.yml). Stack definitions in `vars/{{ type }}.yml` (opinionated, not user-modifiable).

**Template**: Universal `templates/compose.yml.j2` + modular includes (templates/includes/*.j2). Loops `services` list via `svc_data`.

**Networks**: Auto-generated `[stack.name] + stack.additional_networks`. Must exist externally.

## Testing

Separate scenarios per stack. No `molecule/default/`.

```bash
./test-all-scenarios.sh [test|converge|verify]
molecule test -s demo
molecule converge -s demo && molecule verify -s demo
```

**Per scenario**: molecule.yml, prepare.yml (networks), converge.yml, verify.yml, cleanup.yml

## Adding a Stack

1. `vars/{{ type }}.yml`: `services` list with `{{ stack.name }}-<service>` naming, hardcoded config, no networks
2. (Optional) `templates/{{ type }}/` for custom assets
3. `molecule/{{ type }}/` with test files

## Dev Notes

- Validation: tasks/validate.yml
- Stacks are opinionated "as-is"
- Modified versions = new variants
