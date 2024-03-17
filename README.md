# ansible-tf2network

Generally applicable Ansible playbooks for administering a small to medium server network for [**Team Fortress 2**](https://www.teamfortress.com/).<br/>

These playbooks are currently made to support a *separately-hosted* [**SourceBans++**](https://sbpp.github.io/) ban system.

## ✍️ Usage

Ansible requires Linux. If you're running Windows, you'll need to set up **[WSL](https://learn.microsoft.com/en-us/windows/wsl/install)**.

1. Assuming you're using Ubuntu/Debian, install Python, Ansible, and Docker in WSL using `sudo apt-get install python3 ansible docker.io`
2. On all server "hosts":
- 1. `sudo apt-get install docker.io` - Install Docker
- 2. `sudo useradd -Um tf2server` - Create the `tf2server` user
- 3. `sudo usermod -aG docker tf2server` - Grant them the `docker` role

### Creating servers
1. Build your Ansible inventory and global/host variables using the samples:
* `inventory.yml.sample`
* `group_vars/tf2.secret.yml.sample`
* `host_vars/host.secret.yml.sample`
2. `make base` - Build the base Team Fortress 2 server Docker image
3. `make sm` - Distribute and build SourceMod
4. `make srcds` - Build instance images
5. `make deploy` - Start containers & setup crontab
6. `make relay` - Build and start the (early development!!) Discord relay/RCON bot (if configured)
> You can perform all of these in order with simply `make`<br/>
> You can update your admins/reserved slots at any time with `make admins`

## ⭐ Features

### 🛠️ Docker and Ansible, confined scope
**ansible-tf2network** uses Ansible to provide a user-friendly and extensive configuration interface, and Docker to make your deploys consistent regardless of host. If you upgrade or move hosts, all you need to do is point your record in `inventory.yml` at the new IP.

Since the playbooks keep their activity contained within the `tf2server` user folder with *no* actions performed as root, cleaning up a host after using **ansible-tf2network** can be done with these commands:
1. `userdel -r tf2server` - Delete their user
2. `docker stop [...]` - Stop the containers (do this for all servers)
3. `docker container prune` - Remove the containers
4. `docker image prune -a` - Remove all unused Docker images

### 📚 Default, Ruleset, and Instance level configuration
**ansible-tf2network** server configuration has 3 scopes: default, ruleset, and instance. Overriding configuration from outer scopes is possible within inner scopes, e.g., ruleset config overrides default config, and instance config overrides both.

Mapcycle configurations are separate from these scopes, and the mapcycle to be used is defined in the instance scope.

Default, ruleset, and mapcycle configuration is defined in `group_vars/tf2.yml`, and instance config is defined per-host in `host_vars`.

### 📥 All plugin configurations in one place as yaml
Some plugin configuration use Valve's [KeyValues](https://developer.valvesoftware.com/wiki/KeyValues) format (referred to in these playbooks as 'VDF'), and some use Valve's [CFG](https://developer.valvesoftware.com/wiki/CFG) format.

**ansible-tf2network** supports an unlimited amount of both formats by defining a default in the global scope (`group_vars/tf2.yml`, `default_cfgs`, `default_vdfs`), which can be further tweaked in the ruleset and instance scopes. Note that a configuration **must** exist in the global scope in order for it to be included in the server.

**KeyValues** configurations can vary wildly, and as such, the entire configuration must be redefined in the inner scope. **CFG** overriding works as they usually contain all convars set by a plugin.

**Only the secrets are encrypted!** This makes it possible for users to view your server configuration if they're curious, as well as propose changes.

### 💬 Discord Channel <-> Server relay
Using the `discord_relay` plugin (depends on `discord` plugin) and correctly configuring your Discord bot (in `group_vars/tf2.secret.yml` and `host_vars/{host}.yml`) facilitates a **two-way relay** between a specified Discord channel and the Team Fortress 2 server. You can also allow specific Discord user IDs access to the `/rcon` command, which allows remote control of the server.

## 🗒️ To-Do

- [ ] Set up SB++ automatically on a 'metrics' host
- [x] Have `relay` target a 'metrics' host as they do not rely on being on the `tf2` hosts
- [ ] Configuration standardization pass to hopefully reduce confusion

### Pre-commit
There is a pre-commit hook that you should enable to ensure you don't commit any unencrypted secret:<br/>
`ln .hooks/pre-commit .git/hooks/pre-commit`
