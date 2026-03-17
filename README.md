# terraform-hcloud-minecraft-server

Terraform module for deploying a production-ready Minecraft server on [Hetzner Cloud](https://www.hetzner.com/cloud). Ships with PaperMC, optional Bedrock support (GeyserMC + Floodgate), plugin management, automated backups, and security hardening out of the box.

## Features

- Runs PaperMC on a Hetzner Cloud server, provisioned entirely through cloud-init; no Ansible or SSH required during setup
- Bedrock players (iPad, Switch, phone) can join the same server through GeyserMC and Floodgate, installed and configured automatically
- Plugins are installed from a list of URLs in your Terraform config
- World data lives on a separate Hetzner volume so it survives server changes; daily backups are on by default
- Hardened out of the box: Hetzner firewall, UFW, fail2ban, SSH key-only access, and automatic security updates

## Quick start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- A [Hetzner Cloud](https://console.hetzner.cloud/) account and API token
- An SSH key registered in your Hetzner project

### Deploy

```hcl
module "minecraft" {
  source  = "jdwit/minecraft-server/hcloud"
  version = "~> 1.0"

  name        = "mc-server"
  server_type = "cx32"
  location    = "nbg1"
  ssh_keys    = ["my-ssh-key"]

  minecraft_version = "1.21.4"
  motd              = "Welcome to our server!"
  max_players       = 10

  enable_bedrock = true
}
```

```bash
export HCLOUD_TOKEN="your-token-here"
terraform init
terraform plan
terraform apply
```

After a few minutes, your server is ready. Connect with the IP from the output:

- Java Edition: `<ip>:25565`
- Bedrock Edition: `<ip>:19132`

### SSH access

```bash
ssh root@$(terraform output -raw ipv4_address)
```

### Server management

```bash
# view server logs
journalctl -u minecraft -f

# server console (attach to service)
systemctl status minecraft

# restart server
systemctl restart minecraft

# stop server
systemctl stop minecraft
```

## Connecting

### Java Edition

Add a server with the IP address and port `25565` (default).

### Bedrock Edition

When `enable_bedrock = true` (default), Bedrock players can connect on port `19132` (default). GeyserMC translates Bedrock packets to Java, and Floodgate allows Bedrock players to join without a Java account.

Bedrock players will have a `*` prefix on their username by default (configurable in Floodgate's config after first boot).

## Plugin guide

Install plugins by providing a list of direct download URLs:

```hcl
module "minecraft" {
  source = "jdwit/minecraft-server/hcloud"

  # ... other variables ...

  plugins = [
    "https://github.com/MilkBowl/Vault/releases/download/1.7.3/Vault.jar",
    "https://github.com/EssentialsX/Essentials/releases/download/2.20.1/EssentialsX-2.20.1.jar",
    "https://github.com/dmulloy2/ProtocolLib/releases/latest/download/ProtocolLib.jar",
  ]
}
```

### Tips

- Use direct download URLs that point to `.jar` files
- GitHub release URLs work great
- Plugins are downloaded once on first boot; to add more later, SSH in and place them in the plugins directory
- Always check plugin compatibility with your Minecraft version
- Some plugins need configuration after first launch (check their docs)

### Plugin directory

After deployment, plugins live at:

```
/mnt/data/minecraft/plugins/    # with volume (default)
/opt/minecraft/plugins/          # without volume
```

## BedWars example

A full BedWars server setup is in [`examples/bedwars/`](examples/bedwars/). It demonstrates:

- Higher resource allocation for minigame workloads
- Plugin installation (Vault, WorldEdit, ProtocolLib)
- Custom `server.properties` for PvP-focused gameplay
- Operator configuration

To use it as a starting point:

```bash
cd examples/bedwars
cp terraform.tfvars.example terraform.tfvars  # add your token
terraform init
terraform apply
```

After deployment, you'll still need to:
1. SSH in and install your preferred BedWars plugin (e.g., BedWars1058, BedWarsRel)
2. Configure arenas and game settings
3. Set up a lobby and maps

> **Note:** Most BedWars plugins are distributed through SpigotMC and require manual download. Add them to the plugins directory via SSH after first boot or host them somewhere accessible via URL.

## MCSManager

[MCSManager](https://mcsmanager.com/) is an open-source game server management panel that gives you a web UI for starting, stopping, monitoring, and configuring your Minecraft server. This module uses three boolean variables to control which components run on a given server: `game_server`, `mcsmanager_panel`, and `mcsmanager_daemon`. You can combine them freely to suit your deployment topology.

### Default: game server only

By default the module deploys just a Minecraft server with no management panel. This is the simplest setup and works well when you manage the server over SSH:

```hcl
module "minecraft" {
  source  = "jdwit/minecraft-server/hcloud"
  version = "~> 1.0"

  name        = "mc-server"
  server_type = "cx32"
  location    = "nbg1"
  ssh_keys    = ["my-ssh-key"]
}
```

### All-in-one: game server with panel and daemon

When you want a single machine that runs everything, enable all three booleans. The web panel and daemon run alongside the game server, so you can manage it from a browser at `http://<ip>:23333`:

```hcl
module "minecraft" {
  source  = "jdwit/minecraft-server/hcloud"
  version = "~> 1.0"

  name              = "mc-server"
  server_type       = "cx32"
  location          = "nbg1"
  ssh_keys          = ["my-ssh-key"]
  game_server       = true
  mcsmanager_panel  = true
  mcsmanager_daemon = true
}
```

### Pure panel

A dedicated panel server runs only the MCSManager web UI without a game server or daemon. This is useful as the central management hub in a multi-node setup:

```hcl
module "panel" {
  source  = "jdwit/minecraft-server/hcloud"
  version = "~> 1.0"

  name             = "mc-panel"
  server_type      = "cx22"
  location         = "nbg1"
  ssh_keys         = ["my-ssh-key"]
  game_server      = false
  mcsmanager_panel = true
}
```

### Managed node: game server with daemon

A managed node runs a game server and the MCSManager daemon, which registers with a remote panel. Set `panel_host` to the IP of your panel server so the daemon knows where to connect:

```hcl
module "node" {
  source  = "jdwit/minecraft-server/hcloud"
  version = "~> 1.0"

  name              = "mc-node-1"
  server_type       = "cx32"
  location          = "fsn1"
  ssh_keys          = ["my-ssh-key"]
  game_server       = true
  mcsmanager_daemon = true
  panel_host        = module.panel.ipv4_address
}
```

After the node comes up, add it as a remote daemon in the MCSManager panel at `http://<panel-ip>:23333`. The daemon listens on port 24444 by default.

### Multi-node example

A complete multi-node deployment with a dedicated panel and game server node is in [`examples/multi-node/`](examples/multi-node/).

## Examples

| Example | Description |
|---------|-------------|
| [basic](examples/basic/) | Simple survival server with Bedrock support |
| [bedwars](examples/bedwars/) | BedWars minigame server with plugins |
| [multi-node](examples/multi-node/) | Multi-server setup with MCSManager panel and node |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name` | Server name (hostname and resource naming) | `string` | `"minecraft"` |
| `server_type` | Hetzner Cloud server type | `string` | `"cx32"` |
| `location` | Hetzner Cloud location | `string` | `"nbg1"` |
| `image` | OS image | `string` | `"ubuntu-24.04"` |
| `ssh_keys` | SSH key names or IDs | `list(string)` | required |
| `minecraft_version` | Minecraft version | `string` | `"1.21.4"` |
| `paper_build` | PaperMC build number | `string` | `"latest"` |
| `server_port` | Java Edition port | `number` | `25565` |
| `bedrock_port` | Bedrock Edition port | `number` | `19132` |
| `enable_bedrock` | Enable GeyserMC + Floodgate | `bool` | `true` |
| `memory_min` | Min JVM heap | `string` | `"2G"` |
| `memory_max` | Max JVM heap | `string` | `"4G"` |
| `motd` | Server list message | `string` | `"A Minecraft Server"` |
| `max_players` | Maximum players | `number` | `20` |
| `difficulty` | Difficulty level | `string` | `"normal"` |
| `gamemode` | Default game mode | `string` | `"survival"` |
| `seed` | World seed | `string` | `""` |
| `online_mode` | Mojang authentication | `bool` | `true` |
| `enable_whitelist` | Enable whitelist | `bool` | `false` |
| `ops` | Operator usernames | `list(string)` | `[]` |
| `server_properties` | Additional server.properties | `map(string)` | `{}` |
| `plugins` | Plugin JAR URLs | `list(string)` | `[]` |
| `jvm_flags` | Additional JVM flags | `string` | `""` |
| `backup_enabled` | Enable daily backups | `bool` | `true` |
| `backup_retention_days` | Backup retention | `number` | `7` |
| `firewall_additional_rules` | Extra firewall rules | `list(object)` | `[]` |
| `game_server` | Run a Minecraft game server | `bool` | `true` |
| `mcsmanager_panel` | Run MCSManager web panel | `bool` | `false` |
| `mcsmanager_daemon` | Run MCSManager daemon | `bool` | `false` |
| `panel_host` | Panel IP (required when mcsmanager_daemon = true) | `string` | `""` |
| `mcsmanager_port` | MCSManager web panel port | `number` | `23333` |
| `labels` | Resource labels | `map(string)` | `{}` |
| `volume_size` | Data volume size in GB (0 to disable) | `number` | `20` |

## Outputs

| Name | Description |
|------|-------------|
| `server_id` | Hetzner Cloud server ID |
| `server_name` | Server hostname |
| `ipv4_address` | Public IPv4 address |
| `ipv6_address` | Public IPv6 address |
| `java_address` | Java Edition connection address |
| `bedrock_address` | Bedrock Edition connection address |
| `ssh_command` | SSH command |
| `volume_id` | Data volume ID |
| `panel_url` | MCSManager web panel URL |

## Server types

Recommended Hetzner server types for Minecraft:

| Type | vCPU | RAM | Use case |
|------|------|-----|----------|
| `cx22` | 2 | 4 GB | 1-5 players, testing |
| `cx32` | 4 | 8 GB | 5-20 players, small SMP |
| `cx42` | 8 | 16 GB | 20-50 players, minigames |
| `cx52` | 16 | 32 GB | 50+ players, large networks |

## Security

This module applies the following hardening measures:

- Hetzner firewall: only SSH, Java, and Bedrock ports are open
- UFW as host-level defense in depth
- fail2ban for SSH brute-force protection (3 attempts, 1 hour ban)
- SSH hardening: password auth disabled, root login via key only, X11 forwarding off
- Unattended upgrades for automatic security patches

## Cost estimate

Hetzner Cloud pricing (as of 2024, EUR/month):

| Component | cx22 | cx32 | cx42 |
|-----------|------|------|------|
| Server | ~4.35 | ~7.55 | ~14.75 |
| Volume (20 GB) | ~0.96 | ~0.96 | ~0.96 |
| **Total** | **~5.31** | **~8.51** | **~15.71** |

> Prices are approximate. Check [Hetzner pricing](https://www.hetzner.com/cloud) for current rates.

## License

MIT
