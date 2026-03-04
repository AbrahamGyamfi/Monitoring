variable "security_group_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "app_blue_instance_id" {
  type = string
}

variable "app_green_instance_id" {
  type = string
}
