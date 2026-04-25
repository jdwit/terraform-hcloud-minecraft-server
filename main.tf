locals {
  merged_labels = merge({
    managed_by = "terraform"
    service    = "minecraft"
  }, var.labels)

  mc_dir     = var.volume_size > 0 ? "/mnt/data/minecraft" : "/opt/minecraft"
  mount_path = var.volume_size > 0 ? "/mnt/data" : ""
}

# -----------------------------------------------------------------------------
# Firewall
# -----------------------------------------------------------------------------
resource "hcloud_firewall" "minecraft" {
  name   = "${var.name}-firewall"
  labels = local.merged_labels

  # SSH
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Minecraft Java
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = tostring(var.server_port)
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # Minecraft Bedrock (UDP)
  dynamic "rule" {
    for_each = var.enable_bedrock ? [1] : []
    content {
      direction  = "in"
      protocol   = "udp"
      port       = tostring(var.bedrock_port)
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }

  # Additional rules
  dynamic "rule" {
    for_each = var.firewall_additional_rules
    content {
      direction  = rule.value.direction
      protocol   = rule.value.protocol
      port       = rule.value.port
      source_ips = rule.value.source_ips
    }
  }
}

# -----------------------------------------------------------------------------
# Data volume (optional)
# -----------------------------------------------------------------------------
resource "hcloud_volume" "data" {
  count    = var.volume_size > 0 ? 1 : 0
  name     = "${var.name}-data"
  size     = var.volume_size
  location = var.location
  format   = "ext4"
  labels   = local.merged_labels
}

# -----------------------------------------------------------------------------
# Cloud-init template
# -----------------------------------------------------------------------------
data "cloudinit_config" "minecraft" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      mc_dir                    = local.mc_dir
      mount_path                = local.mount_path
      minecraft_version         = var.minecraft_version
      paper_build               = var.paper_build
      server_port               = var.server_port
      bedrock_port              = var.bedrock_port
      enable_bedrock            = var.enable_bedrock
      memory_min                = var.memory_min
      memory_max                = var.memory_max
      motd                      = var.motd
      max_players               = var.max_players
      difficulty                = var.difficulty
      gamemode                  = var.gamemode
      seed                      = var.seed
      online_mode               = var.online_mode
      enable_whitelist          = var.enable_whitelist
      ops                       = var.ops
      server_properties         = var.server_properties
      plugins                   = var.plugins
      jvm_flags                 = var.jvm_flags
      backup_enabled            = var.backup_enabled
      backup_retention_days     = var.backup_retention_days
      volume_enabled            = var.volume_size > 0
      firewall_additional_rules = var.firewall_additional_rules
      plugin_configs            = var.plugin_configs
    })
  }
}

# -----------------------------------------------------------------------------
# Server
# -----------------------------------------------------------------------------
resource "hcloud_server" "minecraft" {
  name        = var.name
  server_type = var.server_type
  location    = var.location
  image       = var.image
  ssh_keys    = var.ssh_keys
  labels      = local.merged_labels
  user_data   = data.cloudinit_config.minecraft.rendered

  firewall_ids = [hcloud_firewall.minecraft.id]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  lifecycle {
    ignore_changes = [user_data, ssh_keys]
  }
}

# -----------------------------------------------------------------------------
# Volume attachment
# -----------------------------------------------------------------------------
resource "hcloud_volume_attachment" "data" {
  count     = var.volume_size > 0 ? 1 : 0
  volume_id = hcloud_volume.data[0].id
  server_id = hcloud_server.minecraft.id
  automount = true
}
