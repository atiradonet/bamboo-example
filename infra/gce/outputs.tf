output "bamboo_lb_ip" {
  description = "Load balancer IP for the Bamboo UI"
  value       = google_compute_global_address.bamboo_ip.address
}

output "bamboo_url" {
  description = "Bamboo UI URL"
  value       = "http://${google_compute_global_address.bamboo_ip.address}"
}

output "bamboo_instance_ip" {
  description = "Direct instance IP (for SSH debugging)"
  value       = google_compute_instance.bamboo.network_interface[0].access_config[0].nat_ip
}
