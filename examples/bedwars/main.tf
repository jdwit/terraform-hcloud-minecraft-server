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
# BedWars server with plugins
#
# This example sets up a PaperMC server with popular BedWars plugins.
# Adjust plugin URLs to match the versions compatible with your Minecraft
# version. Always verify plugin compatibility before deploying.
# ---------------------------------------------------------------------------

module "minecraft" {
  source = "../../"

  name        = "mc-bedwars"
  server_type = "cx32"
  location    = "fsn1"
  ssh_keys    = ["minecraft-server"]

  minecraft_version = "1.21.11"
  memory_min        = "2G"
  memory_max        = "6G"
  motd              = "\\u00A76\\u00A7lBedWars Server \\u00A7r\\u00A77- Join the fight!"
  max_players       = 40
  difficulty        = "normal"
  gamemode          = "adventure"

  enable_bedrock = true
  volume_size    = 40

  # Plugins - update URLs to the latest compatible versions
  # These are example URLs; replace with actual download links
  plugins = [
    # Vault - economy API required by many plugins
    "https://github.com/MilkBowl/Vault/releases/download/1.7.3/Vault.jar",

    # WorldEdit - world manipulation toolkit
    "https://dev.bukkit.org/projects/worldedit/files/latest",

    # ProtocolLib - packet manipulation library
    "https://github.com/dmulloy2/ProtocolLib/releases/latest/download/ProtocolLib.jar",
  ]

  # Server properties for a minigame server
  server_properties = {
    "pvp"                          = "true"
    "spawn-protection"             = "0"
    "allow-nether"                 = "false"
    "spawn-monsters"               = "false"
    "spawn-animals"                = "false"
    "announce-player-achievements" = "false"
  }

  ops = ["your_username"]

  labels = {
    environment = "production"
    game_mode   = "bedwars"
  }
}

output "server_ip" {
  value = module.minecraft.ipv4_address
}

output "java_address" {
  value = module.minecraft.java_address
}

output "bedrock_address" {
  value = module.minecraft.bedrock_address
}

output "ssh_command" {
  value = module.minecraft.ssh_command
}
