output "server_id" {
  description = "Hetzner Cloud server ID"
  value       = hcloud_server.minecraft.id
}

output "server_name" {
  description = "Server hostname"
  value       = hcloud_server.minecraft.name
}

output "ipv4_address" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.minecraft.ipv4_address
}

output "ipv6_address" {
  description = "Public IPv6 address of the server"
  value       = hcloud_server.minecraft.ipv6_address
}

output "java_address" {
  description = "Connection address for Java Edition"
  value       = var.game_server ? "${hcloud_server.minecraft.ipv4_address}:${var.server_port}" : null
}

output "bedrock_address" {
  description = "Connection address for Bedrock Edition (if enabled)"
  value       = var.game_server && var.enable_bedrock ? "${hcloud_server.minecraft.ipv4_address}:${var.bedrock_port}" : null
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.minecraft.ipv4_address}"
}

output "volume_id" {
  description = "Data volume ID (null if volume is disabled)"
  value       = var.volume_size > 0 ? hcloud_volume.data[0].id : null
}

output "panel_url" {
  description = "MCSManager web panel URL (null if panel is not enabled)"
  value       = var.mcsmanager_panel ? "http://${hcloud_server.minecraft.ipv4_address}:${var.mcsmanager_port}" : null
}
