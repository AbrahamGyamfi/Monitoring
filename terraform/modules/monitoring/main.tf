resource "aws_instance" "monitoring" {
  ami                  = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  security_groups      = [var.security_group_name]
  iam_instance_profile = var.iam_instance_profile
  user_data = templatefile("${path.root}/../userdata/monitoring-userdata.sh", {
    region    = var.aws_region
    log_group = var.cloudwatch_log_group
  })

  tags = {
    Name        = "TaskFlow-Monitoring-Server"
    Project     = "TaskFlow"
    Environment = "Production"
  }
}

resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = var.cloudwatch_log_group
  retention_in_days = 7

  tags = {
    Project = "TaskFlow"
  }
}

resource "null_resource" "deploy_monitoring" {
  depends_on = [aws_instance.monitoring]

  triggers = {
    instance_id = aws_instance.monitoring.id
    app_ip      = var.app_public_ip
  }

  provisioner "local-exec" {
    command = "sed 's/APP_SERVER_IP/${var.app_public_ip}/g' ${path.root}/../monitoring/config/prometheus.yml > ${path.root}/../monitoring/config/prometheus-configured.yml"
  }

  provisioner "file" {
    source      = "${path.root}/../monitoring"
    destination = "/home/ec2-user/monitoring"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.monitoring.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 120",
      "cd ~/monitoring",
      "mv config/prometheus-configured.yml config/prometheus.yml || true",
      "docker-compose up -d",
      "sleep 30",
      "for i in {1..10}; do curl -f http://localhost:3000/api/health && break || sleep 10; done"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = aws_instance.monitoring.public_ip
    }
  }
}
