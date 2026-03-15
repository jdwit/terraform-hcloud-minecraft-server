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

module "minecraft" {
  source = "../../"

  name        = "mc-server"
  server_type = "cx32"
  location    = "nbg1"
  ssh_keys    = ["my-ssh-key"]

  minecraft_version = "1.21.4"
  memory_max        = "4G"
  motd              = "Welcome to our server!"
  max_players       = 10
  difficulty        = "normal"
  gamemode          = "survival"

  enable_bedrock = true
  volume_size    = 20

  labels = {
    environment = "production"
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
