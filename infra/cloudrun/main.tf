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

# --- Enable APIs ---

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# --- Cloud Run Service ---

resource "google_cloud_run_v2_service" "app" {
  name     = var.service_name
  location = var.region

  depends_on = [google_project_service.run]

  template {
    containers {
      image = var.image

      ports {
        container_port = 3000
      }

      resources {
        limits = {
          memory = "512Mi"
          cpu    = "1"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }
}

# Allow unauthenticated access (public API for demo)
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.app.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- Load Balancer ---

resource "google_compute_global_address" "app_ip" {
  name = "${var.service_name}-lb-ip"
}

resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  name                  = "${var.service_name}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.app.name
  }
}

resource "google_compute_backend_service" "app" {
  name = "${var.service_name}-backend"

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }
}

resource "google_compute_url_map" "app" {
  name            = "${var.service_name}-url-map"
  default_service = google_compute_backend_service.app.id
}

resource "google_compute_target_http_proxy" "app" {
  name    = "${var.service_name}-http-proxy"
  url_map = google_compute_url_map.app.id
}

resource "google_compute_global_forwarding_rule" "app" {
  name       = "${var.service_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.app.id
  ip_address = google_compute_global_address.app_ip.address
  port_range = "80"
}
