# variables.tf
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
}

variable "droplet_size" {
  description = "Size of the DigitalOcean droplet"
  type        = string
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint for droplet access"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the monitoring stack"
  type        = string
}

variable "private_key_path" {
  description = "Path to SSH private key"
  type        = string
}