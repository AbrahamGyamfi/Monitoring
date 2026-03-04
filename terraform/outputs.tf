output "jenkins_instance_id" {
  description = "Jenkins server instance ID"
  value       = module.compute.jenkins_instance_id
}

output "jenkins_public_ip" {
  description = "Jenkins server public IP"
  value       = module.compute.jenkins_public_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${module.compute.jenkins_public_ip}:8080"
}

output "app_blue_instance_id" {
  description = "Application Blue server instance ID"
  value       = module.compute.app_blue_instance_id
}

output "app_blue_public_ip" {
  description = "Application Blue server public IP"
  value       = module.compute.app_blue_public_ip
}

output "app_green_instance_id" {
  description = "Application Green server instance ID"
  value       = module.compute.app_green_instance_id
}

output "app_green_public_ip" {
  description = "Application Green server public IP"
  value       = module.compute.app_green_public_ip
}

output "load_balancer_dns" {
  description = "Load Balancer DNS name"
  value       = module.loadbalancer.load_balancer_dns
}

output "app_url" {
  description = "Application URL via Load Balancer"
  value       = "http://${module.loadbalancer.load_balancer_dns}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.networking.security_group_id
}

output "ssh_jenkins" {
  description = "SSH command for Jenkins server"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${module.compute.jenkins_public_ip}"
}

output "ssh_app_blue" {
  description = "SSH command for Blue application server"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${module.compute.app_blue_public_ip}"
}

output "ssh_app_green" {
  description = "SSH command for Green application server"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${module.compute.app_green_public_ip}"
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = module.monitoring.prometheus_url
}

output "grafana_url" {
  description = "Grafana URL"
  value       = module.monitoring.grafana_url
}

output "monitoring_public_ip" {
  description = "Monitoring server public IP"
  value       = module.monitoring.monitoring_public_ip
}

output "cloudtrail_bucket" {
  description = "CloudTrail S3 bucket"
  value       = module.security.cloudtrail_bucket
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = module.security.guardduty_detector_id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}
