output "jenkins_instance_id" {
  description = "Jenkins instance ID"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Jenkins public IP"
  value       = aws_instance.jenkins.public_ip
}

output "app_blue_instance_id" {
  description = "App Blue instance ID"
  value       = aws_instance.app_blue.id
}

output "app_blue_public_ip" {
  description = "App Blue public IP"
  value       = aws_instance.app_blue.public_ip
}

output "app_green_instance_id" {
  description = "App Green instance ID"
  value       = aws_instance.app_green.id
}

output "app_green_public_ip" {
  description = "App Green public IP"
  value       = aws_instance.app_green.public_ip
}

output "ami_id" {
  description = "AMI ID used for instances"
  value       = data.aws_ami.amazon_linux_2.id
}
