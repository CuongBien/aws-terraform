# Docker Image Builder
# This module builds and pushes Docker images to ECR before creating instances

resource "null_resource" "build_docker_images" {
  # Trigger rebuild when source code changes
  triggers = {
    backend_dockerfile  = filemd5("${path.module}/../ecommerce-app/backend/Dockerfile")
    frontend_dockerfile = filemd5("${path.module}/../ecommerce-app/frontend/Dockerfile")
    backend_code        = filemd5("${path.module}/../ecommerce-app/backend/server.js")
    frontend_code       = filemd5("${path.module}/../ecommerce-app/frontend/index.html")
  }

  provisioner "local-exec" {
    command     = "powershell.exe -ExecutionPolicy Bypass -File ${path.module}/../scripts/build-and-push-images.ps1"
    working_dir = path.module
  }
}

output "docker_images_built" {
  value       = null_resource.build_docker_images.id
  description = "Docker images build completion indicator"
}
