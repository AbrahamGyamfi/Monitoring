variable "app_instance_id" {
  description = "Application instance ID"
  type        = string
}

variable "app_public_ip" {
  description = "Application public IP"
  type        = string
}

variable "private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "docker_registry" {
  description = "Docker registry URL"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
}
