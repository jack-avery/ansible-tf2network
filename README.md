# rinstagib-server

Ansible playbooks for a server set for **rINSTAGIB** ([trailer video](https://www.youtube.com/watch?v=6GSMJ-zzzig))<br/>
> *... and some other servers*

If you're here for [the rINSTAGIB gamemode](https://github.com/jack-avery/rinstagib)

Enjoy the servers, or just found the playbooks useful? [Buy me a coffee ☕](https://ko-fi.com/raspy)!

## Usage

Ansible requires Linux. If you're running Windows, consider setting up WSL.

1. Run `pip install -r requirements.txt` to install Python requirements.
2. Ensure you have Ansible and Docker installed on your machine.
3. Ensure your Ansible Hosts have Docker installed, and a user named `tf2server` with the `docker` role.

### Creating base image
1. Trigger `make base`.<br/>
-- *Note you probably don't need to run this as the base image the playbooks use is already public on DockerHub.*

### Creating servers
1. Build your Ansible inventory and global/host variables using the samples:
* `inventory.yml.sample`
* `group_vars/tf2.secret.yml.sample`
* `host_vars/local.secret.yml.sample`
2. Trigger `make sm` to distribute and build SourceMod on hosts.
3. Trigger `make srcds` to build images and run servers.
> You can use `make all` instead to do `sm` then `srcds`.

### Updating admins/reserveslots
1. Trigger `make admins`.<br/>
-- Define admins and moderators in `tf2.secret.yml`<br/>
-- Define users with reserve slots to specific servers in `{host}.secret.yml`

## Docs

`group_vars`
* `tf2.secret.yml`<br/>
-- Webhooks, databases, admins/moderators
* `tf2.yml`<br/>
-- Base plugins, default configuration for various plugins, map cycles, rulesets

`host_vars`<br/>
* `{host}.secret.yml`<br/>
-- GSLT, server-specific reserved slots, RCON passwords
* `{host}.yml`<br/>
-- Server settings, plugin configuration overrides.<br/>

**See Jinja2 files in `roles/srcds/templates` for which plugins support overrides currently.**<br/>
If you know Jinja2 and want to add more, note each template will also need a matching `ansible.builtin.template` directive in `roles/srcds/tasks/main.yml`.

## Pre-commit

There is a pre-commit hook that you should enable to ensure you don't commit any unencrypted secret:<br/>
`ln .hooks/pre-commit .git/hooks/pre-commit`