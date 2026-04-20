output "app_lb_ip" {
  description = "Load balancer IP for the application"
  value       = google_compute_global_address.app_ip.address
}

output "app_url" {
  description = "Application URL via load balancer"
  value       = "http://${google_compute_global_address.app_ip.address}"
}

output "cloud_run_url" {
  description = "Direct Cloud Run URL (for debugging)"
  value       = google_cloud_run_v2_service.app.uri
}
