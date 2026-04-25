terraform {
  required_version = ">= 1.5"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

provider "hcloud" {
  token = var.hcloud_token
}

# ---------------------------------------------------------------------------
# Survival server with BlueMap (3D web map on port 8100).
#
# After first boot: SSH in, set `accept-download: true` in
# plugins/BlueMap/core.conf, then restart minecraft.
#
# Pinned to v5.16 since it's compatible with Java 21 (Ubuntu 24.04 default).
# ---------------------------------------------------------------------------

module "minecraft" {
  source = "../../"

  name        = "mc-bluemap"
  server_type = "cx33"
  location    = "nbg1"
  ssh_keys    = ["minecraft-server"]

  motd        = "Survival with BlueMap"
  max_players = 10

  plugins = [
    "https://github.com/BlueMap-Minecraft/BlueMap/releases/download/v5.16/bluemap-5.16-paper.jar",
  ]

  firewall_additional_rules = [
    {
      direction   = "in"
      protocol    = "tcp"
      port        = "8100"
      description = "BlueMap web interface"
    },
  ]

  plugin_configs = {
    "BlueMap/core.conf" = file("${path.module}/bluemap-core.conf")
  }
}

output "java_address" {
  value = module.minecraft.java_address
}

output "bedrock_address" {
  value = module.minecraft.bedrock_address
}

output "bluemap_url" {
  value = "http://${module.minecraft.ipv4_address}:8100"
}

output "ssh_command" {
  value = module.minecraft.ssh_command
}
