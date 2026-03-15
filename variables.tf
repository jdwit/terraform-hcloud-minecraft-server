variable "name" {
  description = "Name of the Minecraft server (used for hostname and resource naming)"
  type        = string
  default     = "minecraft"
}

variable "server_type" {
  description = "Hetzner Cloud server type (e.g. cx22, cx32, cx42)"
  type        = string
  default     = "cx32"
}

variable "location" {
  description = "Hetzner Cloud location (e.g. nbg1, fsn1, hel1, ash)"
  type        = string
  default     = "nbg1"
}

variable "image" {
  description = "OS image for the server"
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_keys" {
  description = "List of SSH key names or IDs to add to the server"
  type        = list(string)
}

variable "minecraft_version" {
  description = "Minecraft version for PaperMC (e.g. 1.21.4)"
  type        = string
  default     = "1.21.4"
}

variable "paper_build" {
  description = "PaperMC build number (use 'latest' for the latest build)"
  type        = string
  default     = "latest"
}

variable "server_port" {
  description = "Minecraft Java Edition server port"
  type        = number
  default     = 25565
}

variable "bedrock_port" {
  description = "Minecraft Bedrock Edition port (via GeyserMC)"
  type        = number
  default     = 19132
}

variable "enable_bedrock" {
  description = "Enable Bedrock support via GeyserMC and Floodgate"
  type        = bool
  default     = true
}

variable "memory_min" {
  description = "Minimum JVM heap size (e.g. 1G, 2G)"
  type        = string
  default     = "2G"
}

variable "memory_max" {
  description = "Maximum JVM heap size (e.g. 4G, 8G)"
  type        = string
  default     = "4G"
}

variable "motd" {
  description = "Message of the day shown in the server list"
  type        = string
  default     = "A Minecraft Server"
}

variable "max_players" {
  description = "Maximum number of players"
  type        = number
  default     = 20
}

variable "difficulty" {
  description = "Server difficulty (peaceful, easy, normal, hard)"
  type        = string
  default     = "normal"

  validation {
    condition     = contains(["peaceful", "easy", "normal", "hard"], var.difficulty)
    error_message = "Difficulty must be one of: peaceful, easy, normal, hard."
  }
}

variable "gamemode" {
  description = "Default game mode (survival, creative, adventure, spectator)"
  type        = string
  default     = "survival"

  validation {
    condition     = contains(["survival", "creative", "adventure", "spectator"], var.gamemode)
    error_message = "Gamemode must be one of: survival, creative, adventure, spectator."
  }
}

variable "seed" {
  description = "World seed (leave empty for random)"
  type        = string
  default     = ""
}

variable "online_mode" {
  description = "Enforce Mojang authentication (set to false when using Floodgate for Bedrock)"
  type        = bool
  default     = true
}

variable "enable_whitelist" {
  description = "Enable server whitelist"
  type        = bool
  default     = false
}

variable "ops" {
  description = "List of player usernames to grant operator status"
  type        = list(string)
  default     = []
}

variable "server_properties" {
  description = "Additional server.properties key-value pairs (override defaults)"
  type        = map(string)
  default     = {}
}

variable "plugins" {
  description = "List of plugin JAR URLs to download into the plugins directory"
  type        = list(string)
  default     = []
}

variable "jvm_flags" {
  description = "Additional JVM flags (Aikar's flags are included by default)"
  type        = string
  default     = ""
}

variable "backup_enabled" {
  description = "Enable daily world backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "firewall_additional_rules" {
  description = "Additional firewall rules to apply"
  type = list(object({
    direction   = string
    protocol    = string
    port        = string
    source_ips  = optional(list(string), ["0.0.0.0/0", "::/0"])
    description = optional(string, "")
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "volume_size" {
  description = "Size of the data volume in GB (0 to disable)"
  type        = number
  default     = 20
}
