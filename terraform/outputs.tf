output "droplet_ip" {
  value = digitalocean_droplet.monitoring.ipv4_address
}

output "prometheus_url" {
  value = "https://prometheus.${var.domain_name}"
}

output "grafana_url" {
  value = "https://grafana.${var.domain_name}"
}

output "alertmanager_url" {
  value = "https://alertmanager.${var.domain_name}"
}

output "loki_url" {
  value = "https://loki.${var.domain_name}"
}

output "digitalocean_name_servers" {
  value = digitalocean_domain.monitoring.id
}

