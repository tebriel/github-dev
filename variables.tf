variable "admin_password" {
  description = "The password for the admin account"
}

variable "admin_username" {
  description = "The username for the admin account"
}

variable "home_ip" {
  description = "The IP of home."
}

variable "anduril_enable" {
  description = "If anduril is enabled"
  default     = 0
}

variable "rivendell_enable" {
  description = "If rivendell is enabled"
  default     = 0
}

variable "kusto_enable" {
  description = "If kusto database is enabled"
  default     = 0
}
