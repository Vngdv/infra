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
  name     = "k3s-cluster-network"
  ip_range = "10.0.1.0/16"
}

resource "hcloud_network_subnet" "cluster_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.cluster_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_firewall" "cluster_firewall" {
  name = "cluster_firewall"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "6443"
    source_ips = [
      var.personal_ip,
    ]
  }

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
    count = "${var.cluster_master_count}"
    name        = "master-${count.index}"
    image       = data.hcloud_image.snapshot_fedora_coreos.id
    server_type = "${var.cluster_master_server_type}"
    firewall_ids = [hcloud_firewall.cluster_firewall.id]
    public_net {
        ipv4_enabled = true
        ipv6_enabled = true
    }

    labels = {
        type = "master"
    }

    network {
      network_id = hcloud_network.cluster_network.id
      ip         = "10.0.1.${count.index + 100}"
    }

    delete_protection = true
    ssh_keys = [for key, ssh_key in hcloud_ssh_key.main : ssh_key.id]

    user_data = templatefile("${path.module}/templates/k3s-master-install.sh", {
      first_master      = count.index == 0 ? true : false
      cluster_token     = random_password.cluster_token.result,
      api_server_ip     = "10.0.1.100"
      api_server_port   = 6443
    })

    depends_on = [
      hcloud_network_subnet.cluster_subnet
    ]
}

