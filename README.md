# ansible-tf2network

Generally applicable Ansible playbooks for administering a small to medium server network for [**Team Fortress 2**](https://www.teamfortress.com/).<br/>

These playbooks are currently made to support a *separately-hosted* [**SourceBans++**](https://sbpp.github.io/) ban system.

## Usage

Ansible requires Linux. If you're running Windows, consider setting up WSL.

1. Run `pip install -r requirements.txt` to install Python requirements.
2. Ensure you have Ansible and Docker installed on your machine.
3. Ensure your Ansible Hosts have Docker installed, and a user named `tf2server` with the `docker` role.

### Creating servers
1. Build your Ansible inventory and global/host variables using the samples:
* `inventory.yml.sample`
* `group_vars/tf2.secret.yml.sample`
* `host_vars/host.secret.yml.sample`
2. Trigger `make base` to build the base Team Fortress 2 server image.
3. Trigger `make sm` to distribute and build SourceMod on hosts.
4. Trigger `make srcds` to build images.
5. Trigger `make deploy` to start up the new images.
> You can use `make` as an alias for `make sm srcds deploy`</br>
> You can narrow which instances passing `ONLY`, e.g. `make srcds ONLY=myserver,myotherserver`</br>
> You will need to run `make base` for each update; this is not included in `make (all)`</br>

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

## Pre-commit

There is a pre-commit hook that you should enable to ensure you don't commit any unencrypted secret:<br/>
`ln .hooks/pre-commit .git/hooks/pre-commit`