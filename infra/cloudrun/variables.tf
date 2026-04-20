variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "image" {
  description = "Container image to deploy (e.g. gcr.io/PROJECT/bamboo-example-app:latest)"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "bamboo-example-app"
}
