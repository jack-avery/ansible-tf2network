# ansible-tf2network

Generally applicable Ansible playbooks for administering a server network for [**Team Fortress 2**](https://www.teamfortress.com/).<br>

**Want to see what makes this better than the alternatives?** Check out [the Features](#-features).

## ✍️ Usage

Ansible requires Linux. If you're running Windows, you'll need to set up **[WSL](https://learn.microsoft.com/en-us/windows/wsl/install)**.
These playbooks only work with [systemd](https://systemd.io/)-based hosts, which is the default for most Linux distributions.

### Mandatory setup
1. Assuming you're using Ubuntu (WSL default), install Ansible using `sudo apt install ansible`
> NixOS users: a flake is provided for convenience, just run `nix develop`.

2. On all hosts (dedicated servers):
- 1. `sudo apt install -y podman kubernetes` - Install Podman and Kubernetes.
- 2. `sudo useradd -Um tf2server` - Create the `tf2server`.
- 3. `sudo loginctl enable-linger tf2server` - Enable systemd service lingering on the user.

Of course, don't forget to put your SSH public key in `/home/tf2server/.ssh/authorized_keys`.

There is a pre-commit hook that you should enable to ensure you don't commit any unencrypted secret:<br/>
`ln .hooks/pre-commit .git/hooks/pre-commit`

### Creating servers
1. Build your Ansible inventory and global/host variables using the samples:
* `inventory.yml.sample`
* `group_vars/tf2.yml.sample`
* `group_vars/tf2.secret.yml.sample`
* `host_vars/host.yml.sample`
* `host_vars/host.secret.yml.sample`
2. `make sbpp-install` - Install SourceBans++ on your `metrics` host. <br>
-- Make sure to access it at the address & port to complete necessary setup manually.<br>
> DB host: `db`<br>
> DB user: `sourcebans`<br>
> DB name: `sourcebans`<br>
> Configure the rest to your liking.
3. `make cycle` - Generate initial ssh keys for secure SB++ DB connection.
-- This directive also (re-)starts the SB++ network, so no need to run `make sbpp`.
4. `make base` - Build the base Team Fortress 2 server image on every `tf2` host.
5. `make sm` - Distribute and build SourceMod.
6. `make srcds` - Build instance images.
7. `make deploy` - Start containers & setup crontab for the TF2 servers.
8. `make relay` - If configured & enabled, build the Discord -> Server relay/RCON bot on your `metrics` host.
9. `make relay-deploy` - Deploy the bot on your `metrics` host.
> `make all` or simply `make` is an alias for `make sm srcds deploy relay relay-deploy`<br>
> You can update your admins/reserved slots at any time with `make admins`

**`make base` can take a long time!**
This is because it's downloading the full TF2 server.<br>
**It is possible that Ansible will *SILENTLY* time out while waiting if it takes too long!**<br>
Watch for `jackavery/base-tf2server` to show up in `podman image ls`. If it's there, you can Ctrl+C Ansible.

**Do not re-run `make sbpp-install` once you've installed SB++!**
This is because it starts the container with intent to install SourceBans++.<br>
**This also means it will wipe your existing data, including user punishments and server configuration.**

## ⭐ Features

### 💸 More for Cheaper
Because **ansible-tf2network** handles everything for you, you can look for cheap **VPS Providers** instead of managed hosting services. A lot of managed services will upcharge you for their ease of use; but, trying to do anything outside of the scope of what their management dashboard allows you to do is *difficult*. Going directly to a VPS provider and purchasing a box directly may be cheaper, and with **ansible-tf2network**, you can do more.

### 💬 Discord Channel <-> Server relay
Using the `discord_relay` plugin (depends on `discord` plugin, uses a webhook in `host_vars/{host}.secret.yml`) facilitates a Server to Discord relay, and correctly configuring your Discord bot (in `group_vars/tf2.secret.yml` and `host_vars/{host}.yml`) facilitates a Discord to Server relay between a specified Discord channel and Team Fortress 2 server. You can also allow specific Discord user IDs access to the `/rcon` command, which allows remote control of the server network.

### 👏 Hands-off Maintenance
This playbook set comes with a robust and simple auto-update script that ensures your servers update as soon as a new version of Team Fortress 2 is available. This is done by rebuilding from *scratch*, instead of updating the existing image, so as to maintain [image immutability](https://kubernetes.io/blog/2018/03/principles-of-container-app-design/). Servers are restarted once daily at a time set per-host as to prevent [server clock errors](https://www.youtube.com/watch?v=RdTJHVG_IdU). The relay plugin facilitates chat logs with user IDs for use by moderators for moderation decisions. This leads to a seamless 24/7 server experience with quality-of-life for your moderation team.

### 🛠️ Podman and Ansible, confined scope, highly secure
**ansible-tf2network** uses Ansible to provide a user-friendly and extensive configuration interface, and Podman to make your deploys consistent regardless of host. If you upgrade or move hosts, all you need to do is point your host record in `inventory.yml` at the new IP. Multiple measures have been put in place to ensure 

Since the playbooks keep their activity contained within the `tf2server` user folder with *no* actions performed as root, cleaning up a host after using **ansible-tf2network** can be done with these commands:
1. `userdel -r tf2server` - Delete their user
2. `systemctl daemon-reload` - Reload systemd (to teardown their containers)
3. `podman system prune -a` - Prune Podman

### 📚 Default, Ruleset, and Instance level configuration
**ansible-tf2network** server configuration has 3 scopes: default, ruleset, and instance. Overriding configuration from outer scopes is possible within inner scopes, e.g., ruleset config overrides default config, and instance config overrides both.

Mapcycle configurations are separate from these scopes, and the mapcycle to be used is defined in the instance scope.

Default, ruleset, and mapcycle configuration is defined in `group_vars/tf2.yml`, and instance config is defined per-host in `host_vars`.

### 📥 All plugin configurations in one place as yaml
Some plugin configuration use Valve's [KeyValues](https://developer.valvesoftware.com/wiki/KeyValues) format (referred to in these playbooks as 'VDF'), and some use Valve's [CFG](https://developer.valvesoftware.com/wiki/CFG) format.

**ansible-tf2network** supports an unlimited amount of both formats by defining a default in the global scope (`group_vars/tf2.yml`, `default_cfgs`, `default_vdfs`), which can be further tweaked in the ruleset and instance scopes. Note that a configuration **must** exist in the global scope in order for it to be included in the server.

**KeyValues** configurations can vary wildly, and as such, the entire configuration must be redefined in the inner scope. **CFG** overriding works as they usually contain all convars set by a plugin.

**Only the secrets are encrypted!** This makes it possible for users to view your server configuration if they're curious, as well as propose changes.
