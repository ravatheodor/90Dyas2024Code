terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "1.1.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "5.10.0"
    }
  }
}

provider "google" {
  region  = var.gcp_region
  zone    = var.gcp_zone
  project = var.gcp_project
}

###############
### NETWORK ###
###############

resource "google_compute_network" "main" {
  for_each                = var.networks
  name                    = "vpc-${each.key}-${var.user_id}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "main" {
  for_each                 = var.networks
  name                     = "subnet-${each.key}-${var.user_id}"
  ip_cidr_range            = each.value
  network                  = google_compute_network.main[each.key].id
  private_ip_google_access = "true"
}

resource "google_compute_firewall" "allow" {
  for_each = var.fwl_allowed_tcp_ports
  name     = "allow-${each.key}"
  network  = google_compute_network.main[each.key].name

  allow {
    protocol = "tcp"
    ports    = each.value
  }

  source_ranges = ["0.0.0.0/0"] # this is not a best practice

  depends_on = [
    google_compute_network.main
  ]
}

# ##############
# ### WEB VM ###
# ##############

resource "google_compute_instance" "web" {
  name         = "web-vm-${var.user_id}"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2310-mantic-amd64-v20231215"
    }
  }

  network_interface {
    network    = google_compute_network.main["web"].self_link
    subnetwork = google_compute_subnetwork.main["web"].self_link
    access_config {}
  }

# ssh key for connection to the deployed VM - we don't show it in here
  metadata = {
    "ssh-keys" = <<EOT
      your_user:ssh-rsa ABCDEFG
     EOT
  }

}

############################################
### Cofiguration management with Ansible ###
############################################

resource "time_sleep" "wait_20_seconds" {
  depends_on      = [google_compute_instance.web]
  create_duration = "20s"
}

resource "ansible_host" "gcp_instance" {
  name   = google_compute_instance.web.network_interface.0.access_config.0.nat_ip
  groups = ["web"]
  variables = {
    ansible_user                 = "${var.ansible_user}",
    ansible_ssh_private_key_file = "${var.ansible_ssh_key}",
    ansible_python_interpreter   = "${var.ansible_python}"
  }

  depends_on = [time_sleep.wait_20_seconds]
}

# graph is to not needed, but it's nice to see it
resource "terraform_data" "ansible_inventory" {
  provisioner "local-exec" {
    command = "ansible-inventory -i  ./ansible/inventory.yml --graph"
  }
  depends_on = [ansible_host.gcp_instance]
}

# run the playbook on the newly deployed hosts
resource "terraform_data" "ansible_playbook" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ./ansible/inventory.yml ./ansible/web_vm.yml"
  }
  depends_on = [terraform_data.ansible_inventory]
}
