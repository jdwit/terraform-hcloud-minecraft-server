# Multi-node Minecraft setup with MCSManager
#
# This example deploys a central panel server, plus a game server node that
# registers its daemon with the panel for centralized management.

variable "ssh_keys" {
  description = "SSH key names or IDs"
  type        = list(string)
}

module "panel" {
  source = "../.."

  name             = "mc-panel"
  server_type      = "cx22"
  location         = "nbg1"
  ssh_keys         = var.ssh_keys
  game_server      = false
  mcsmanager_panel = true
}

module "node_1" {
  source = "../.."

  name              = "mc-node-1"
  server_type       = "cx32"
  location          = "fsn1"
  ssh_keys          = var.ssh_keys
  game_server       = true
  mcsmanager_daemon = true
  panel_host        = module.panel.ipv4_address

  minecraft_version = "1.21.4"
  motd              = "Node 1"
  max_players       = 20
}

output "panel_url" {
  description = "MCSManager panel URL"
  value       = module.panel.panel_url
}

output "panel_ip" {
  description = "Panel server IP"
  value       = module.panel.ipv4_address
}

output "node_1_ip" {
  description = "Node 1 IP"
  value       = module.node_1.ipv4_address
}
