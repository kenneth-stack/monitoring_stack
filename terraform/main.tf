terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
       version = "~>2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token

}  

resource "digitalocean_droplet" "monitoring" {
  image    = "ubuntu-22-04-x64"
  name     = "monitoring-stack"
  region   = var.region
  size     = var.droplet_size
  ssh_keys = [var.ssh_key_fingerprint]


  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.private_key_path)
  }

  provisioner "file" {
    source      = "../scripts"
    destination = "/tmp"
  }

  provisioner "file" {
    source      = "../config"
    destination = "/tmp"
  }

  provisioner "remote-exec" {
    inline = [
      "ls -la /tmp/scripts",  
      "pwd",  
      "chmod +x /tmp/scripts/*.sh",
      "bash -x /tmp/scripts/setup_monitoring.sh", 
      "echo 'xxxxx@gmail.com' | certbot certonly --dns-digitalocean --dns-digitalocean-propagation-seconds 60 -d ${var.domain_name} -d *.${var.domain_name}",
      "sudo certbot renew --keep-until-expiring --non-interactive"

    ]
  }
}

resource "digitalocean_domain" "monitoring" {
  name = var.domain_name
}

resource "digitalocean_record" "root_domain" {
  domain = digitalocean_domain.monitoring.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.monitoring.ipv4_address
}

resource "digitalocean_record" "wildcard" {
  domain = digitalocean_domain.monitoring.name
  type   = "A"
  name   = "*"
  value  = digitalocean_droplet.monitoring.ipv4_address
}


resource "digitalocean_record" "prometheus" {
  domain = digitalocean_domain.monitoring.name
  type   = "A"
  name   = "prometheus"
  value  = digitalocean_droplet.monitoring.ipv4_address
}

resource "digitalocean_record" "grafana" {
  domain = digitalocean_domain.monitoring.name
  type   = "A"
  name   = "grafana"
  value  = digitalocean_droplet.monitoring.ipv4_address
}

resource "digitalocean_record" "alertmanager" {
  domain = digitalocean_domain.monitoring.name
  type   = "A"
  name   = "alertmanager"
  value  = digitalocean_droplet.monitoring.ipv4_address
}

resource "digitalocean_record" "loki" {
  domain = digitalocean_domain.monitoring.name
  type   = "A"
  name   = "loki"
  value  = digitalocean_droplet.monitoring.ipv4_address
}
