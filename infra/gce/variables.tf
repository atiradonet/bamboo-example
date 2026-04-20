variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCE zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "GCE instance machine type (Bamboo needs ~2 GB RAM minimum)"
  type        = string
  default     = "e2-medium"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "bamboo-network"
}
