terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- Networking ---

resource "google_compute_network" "bamboo" {
  name                    = var.network_name
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.bamboo.id

  allow {
    protocol = "tcp"
    ports    = ["8085"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bamboo-server"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.bamboo.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["bamboo-server"]
}

resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.network_name}-allow-health-check"
  network = google_compute_network.bamboo.id

  allow {
    protocol = "tcp"
    ports    = ["8085"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["bamboo-server"]
}

# --- Compute ---

resource "google_compute_instance" "bamboo" {
  name         = "bamboo-server"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["bamboo-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = google_compute_network.bamboo.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    scopes = ["cloud-platform"]
  }
}

# --- Load Balancer ---

resource "google_compute_global_address" "bamboo_ip" {
  name = "bamboo-lb-ip"
}

resource "google_compute_instance_group" "bamboo" {
  name = "bamboo-instance-group"
  zone = var.zone

  instances = [google_compute_instance.bamboo.id]

  named_port {
    name = "http"
    port = 8085
  }
}

resource "google_compute_health_check" "bamboo" {
  name = "bamboo-health-check"

  timeout_sec         = 10
  check_interval_sec  = 15
  healthy_threshold   = 2
  unhealthy_threshold = 10

  tcp_health_check {
    port = 8085
  }
}

resource "google_compute_backend_service" "bamboo" {
  name          = "bamboo-backend"
  protocol      = "HTTP"
  port_name     = "http"
  health_checks = [google_compute_health_check.bamboo.id]

  backend {
    group = google_compute_instance_group.bamboo.id
  }
}

resource "google_compute_url_map" "bamboo" {
  name            = "bamboo-url-map"
  default_service = google_compute_backend_service.bamboo.id
}

resource "google_compute_target_http_proxy" "bamboo" {
  name    = "bamboo-http-proxy"
  url_map = google_compute_url_map.bamboo.id
}

resource "google_compute_global_forwarding_rule" "bamboo" {
  name       = "bamboo-forwarding-rule"
  target     = google_compute_target_http_proxy.bamboo.id
  ip_address = google_compute_global_address.bamboo_ip.address
  port_range = "80"
}
