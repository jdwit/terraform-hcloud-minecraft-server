<p align="center">
  <img src="https://raw.githubusercontent.com/jdwit/terraform-hcloud-minecraft-server/refs/heads/main/hcloud-minecraft-cover.png" alt="terraform-hcloud-minecraft-server" width="100%" />
</p>

<p align="center">
  <a href="https://registry.terraform.io/modules/jdwit/minecraft-server/hcloud/latest"><img src="https://img.shields.io/badge/Terraform%20Registry-jdwit%2Fminecraft--server%2Fhcloud-844FBA?logo=terraform&logoColor=white" alt="Terraform Registry" /></a>
  <a href="https://github.com/jdwit/terraform-hcloud-minecraft-server/releases"><img src="https://img.shields.io/github/v/release/jdwit/terraform-hcloud-minecraft-server?logo=github&label=release" alt="GitHub release" /></a>
  <img src="https://img.shields.io/badge/terraform-%3E%3D%201.5-623CE4?logo=terraform&logoColor=white" alt="Terraform >= 1.5" />
</p>

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

  minecraft_version = "1.21.11"
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

## Examples

| Example | Description |
|---------|-------------|
| [basic](examples/basic/) | Simple survival server with Bedrock support |
| [bedwars](examples/bedwars/) | BedWars minigame server with plugins |
| [bluemap](examples/bluemap/) | Survival server with BlueMap 3D web map on port 8100 |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `name` | Server name (hostname and resource naming) | `string` | `"minecraft"` |
| `server_type` | Hetzner Cloud server type | `string` | `"cx32"` |
| `location` | Hetzner Cloud location | `string` | `"nbg1"` |
| `image` | OS image | `string` | `"ubuntu-24.04"` |
| `ssh_keys` | SSH key names or IDs | `list(string)` | required |
| `minecraft_version` | Minecraft version | `string` | `"1.21.11"` |
| `paper_build` | PaperMC build number | `string` | `"latest"` |
| `server_port` | Java Edition port | `number` | `25565` |
| `bedrock_port` | Bedrock Edition port | `number` | `19132` |
| `enable_bedrock` | Enable GeyserMC + Floodgate | `bool` | `true` |
| `memory_min` | Min JVM heap | `string` | `"2G"` |
| `memory_max` | Max JVM heap | `string` | `"4G"` |
| `motd` | Server list message | `string` | `"Minecraft on Hetzner Cloud"` |
| `max_players` | Maximum players | `number` | `20` |
| `difficulty` | Difficulty level | `string` | `"normal"` |
| `gamemode` | Default game mode | `string` | `"survival"` |
| `seed` | World seed | `string` | `""` |
| `online_mode` | Mojang authentication | `bool` | `true` |
| `enable_whitelist` | Enable whitelist | `bool` | `false` |
| `ops` | Operator usernames | `list(string)` | `[]` |
| `server_properties` | Additional server.properties | `map(string)` | `{}` |
| `plugins` | Plugin JAR URLs | `list(string)` | `[]` |
| `plugin_configs` | Pre-populated plugin config files (path relative to `plugins/`) | `map(string)` | `{}` |
| `jvm_flags` | Additional JVM flags | `string` | `""` |
| `backup_enabled` | Enable daily backups | `bool` | `true` |
| `backup_retention_days` | Backup retention | `number` | `7` |
| `firewall_additional_rules` | Extra firewall rules | `list(object)` | `[]` |
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

## Server types

Recommended Hetzner server types for Minecraft:

| Type | vCPU | RAM | Use case |
|------|------|-----|----------|
| `cx23` | 2 | 4 GB | 1-5 players, testing |
| `cx33` | 4 | 8 GB | 5-20 players, small SMP |
| `cx43` | 8 | 16 GB | 20-50 players, minigames |
| `cx53` | 16 | 32 GB | 50+ players, large networks |

## Security

This module applies the following hardening measures:

- Hetzner firewall: only SSH, Java, and Bedrock ports are open
- UFW as host-level defense in depth
- fail2ban for SSH brute-force protection (3 failed attempts within 10 minutes triggers a 1 hour ban)
- SSH hardening: password authentication disabled, root login restricted to public-key auth, X11 forwarding off
- Unattended upgrades for automatic security patches
