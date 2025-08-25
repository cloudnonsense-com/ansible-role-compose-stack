# Ansible Role: compose-stack

This Ansible role manages Docker Compose v2 stacks.  
It allows you to deploy, restart, and remove application stacks in a consistent and idempotent way using a simple set of variables.

---

## Features

- Creates an application directory for each stack.
- Renders a `compose.yml` file from a Jinja2 template.
- Starts and manages the lifecycle of a Docker Compose v2 project.
- Supports stopping and removing stacks cleanly.
- Includes Molecule tests for validation.

---

## Requirements

- **Ansible** ≥ 2.12  
- **Docker Engine** running on the target host.  
- **Docker Compose v2 plugin** installed.  
- Python libraries: `docker` and `docker-compose` (usually bundled with `community.docker`).  

---

## Role Variables

Default variables are defined in [`defaults/main.yml`](defaults/main.yml):

```yaml
compose_stacks_base_dir:  "/opt/apps"
compose_stack_state:      "present"
compose_stack_file_owner: "root"
compose_stack_file_mode:  "0644"
compose_stack_dir_mode:   "0755"

compose_stack_name:       ""    # demo value: "nginx-demo"
compose_stack_http_host:  ""    # demo value: "nginx-demo.example.lan"

compose_stack_src_file: "apps/{{ compose_stack_name }}/compose.yml.j2"
compose_stack_dst_dir:  "{{ compose_stacks_base_dir }}/{{ compose_stack_name }}"
```
============================================================================================================
## Key Variables

`compose_stack_name`
  * Name of the application stack. Used in directory paths and as a reference.
  * Example: nginx-demo

`compose_stack_state`
  * Desired state of the stack:
  * `present` → deploy or update the stack
  * `absent` → remove the stack

`compose_stack_src_file`
  * Path to the Jinja2 template that will render into `compose.yml`.

`compose_stack_dst_dir`
  * Destination directory for the stack. Defaults to `{{ compose_stacks_base_dir }}/{{ compose_stack_name }}`.

## Handlers
The role includes the following handler:
  * `restart compose stack` 
  * Restarts the stack using community.docker.docker_compose_v2.

## Example Usage
### Playbook
```yaml
- hosts: docker_hosts
  roles:
    - role: ansible-role-compose-stack
      vars:
        compose_stack_name: "nginx-demo"
        compose_stack_http_host: "nginx-demo.example.lan"
```

## License
MIT

## Author
compose-stack role by [CloudNonsense.com]