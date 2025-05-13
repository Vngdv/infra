locals {
  node_first_ip_index = 100
  node_network_cidr = "10.1.1.0/24"
  api_server_ip = cidrhost(local.node_network_cidr, local.node_first_ip_index)
  api_server_port = 6443
}

data "ignition_config" "cluster_master_ignition" {
  count = var.cluster_master_count
  content = templatefile("${path.module}/templates/k3s-master-install.yaml", {
    node_index        = count.index
    cluster_token     = random_password.cluster_token.result
    api_server_ip     = local.api_server_ip
    api_server_port   = local.api_server_port
    node_ip           = cidrhost(local.node_network_cidr, local.node_first_ip_index + count.index)
  })
}

data "hcloud_image" "snapshot_fedora_coreos" {
  with_selector = "os=fedora-coreos"
  most_recent = true
}

resource "random_password" "cluster_token" {
  length  = 64
  special = false
}

resource "hcloud_ssh_key" "main" {
    for_each = toset(var.ssh_keys)
    name       = "main-ssh-key"
    public_key = "${each.value}"
}

resource "hcloud_network" "cluster_network" {
  name     = "cluster_network"
  ip_range = "10.1.0.0/16"
}

resource "hcloud_network_subnet" "cluster_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.cluster_network.id
  network_zone = "eu-central"
  ip_range     = "10.1.1.0/24"
}

resource "hcloud_placement_group" "cluster_placement_group" {
  name     = "cluster_placement_group"
  type     = "spread"
}

resource "hcloud_firewall" "cluster_firewall" {
  name = "cluster_firewall"

  # Allow all internal traffic inside the subnet
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "any"
    source_ips = [
        hcloud_network_subnet.cluster_subnet.ip_range
    ]
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "any"
    source_ips = [
        hcloud_network_subnet.cluster_subnet.ip_range
    ]
  }

  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
        hcloud_network_subnet.cluster_subnet.ip_range
    ]
  }

  # Allow Kubernetes API traffic from my personal IP
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      var.personal_ip,
    ]
  }

  # Allow SSH traffic from my personal IP
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      var.personal_ip,
    ]
  }

}

# Create a new server running debian
resource "hcloud_server" "cluster_master" {
    count         = var.cluster_master_count
    name          = "master-${count.index}"
    image         = data.hcloud_image.snapshot_fedora_coreos.id
    server_type   = var.cluster_master_server_type
    firewall_ids  = [hcloud_firewall.cluster_firewall.id]

    location            = var.cluster_location
    placement_group_id  = hcloud_placement_group.cluster_placement_group.id

    public_net {
        ipv4_enabled = true
        ipv6_enabled = true
    }

    labels = {
        type = "master"
    }

    network {
      network_id = hcloud_network.cluster_network.id
      ip         = "10.1.1.${count.index + 100}"
    }
    
    ssh_keys = [for key, ssh_key in hcloud_ssh_key.main : ssh_key.id]

    user_data = data.ignition_config.cluster_master_ignition[count.index].rendered
  
    depends_on = [
      hcloud_network_subnet.cluster_subnet
    ]
}

