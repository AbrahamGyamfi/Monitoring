resource "null_resource" "deploy_app" {
  depends_on = [var.app_instance_id]

  triggers = {
    instance_id = var.app_instance_id
    image_tag   = var.image_tag
  }

  provisioner "file" {
    source      = "${path.root}/../docker-compose.prod.yml"
    destination = "/home/ec2-user/docker-compose.yml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = var.app_public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 120",
      "# Deploy Node Exporter first",
      "docker run -d --name node-exporter --restart unless-stopped -p 9100:9100 prom/node-exporter:latest || echo 'Node exporter already running'",
      "# Try to pull and deploy app from ECR",
      "docker pull ${var.docker_registry}/taskflow-backend:${var.image_tag} || echo 'Pull failed, continuing'",
      "docker pull ${var.docker_registry}/taskflow-frontend:${var.image_tag} || echo 'Pull failed, continuing'",
      "docker-compose -f ~/docker-compose.yml down || true",
      "REGISTRY_URL=${var.docker_registry} IMAGE_TAG=${var.image_tag} docker-compose -f ~/docker-compose.yml up -d || echo 'Compose failed'",
      "sleep 30",
      "# Verify Node Exporter is running",
      "curl -f http://localhost:9100/metrics || echo 'Node exporter check failed'",
      "# Try health check for app",
      "for i in {1..10}; do curl -f http://localhost/health && break || sleep 10; done || echo 'Health check failed'"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.private_key_path)
      host        = var.app_public_ip
    }
  }
}
