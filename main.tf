# n8n instances (SQLite-only)
resource "docker_image" "n8n_images" {
  for_each = local.instances

  name = each.value.image
}

resource "random_password" "n8n_encryption_key" {
  for_each = local.instances
  length   = 24
  special  = true
}

resource "docker_volume" "n8n_data" {
  for_each = local.instances

  name = "${local.resource_prefix}n8n-data-${each.value.hostname}"
}

resource "docker_container" "n8n_instances" {
  for_each = local.instances

  name  = "${local.resource_prefix}n8n-${each.value.hostname}"
  image = docker_image.n8n_images[each.key].image_id

  env = [
    "DB_TYPE=sqlite",
    "DB_SQLITE_DATABASE=/home/node/.n8n/database.sqlite",

    "N8N_HOST=${each.value.hostname}.localhost",
    "N8N_PORT=5678",
    "WEBHOOK_URL=http://${each.value.hostname}.localhost:5678/",
    "N8N_ENCRYPTION_KEY=${random_password.n8n_encryption_key[each.key].result}",

    # Secure Cookie settings (adjust for local dev if needed)
    "N8N_SECURE_COOKIE=false"
  ]

  ports {
    internal = 5678
    # In reality, you'd use a reverse proxy or map to different host ports
    # For now, let's let Docker map random ports or we need to manage them in config
    external = 5678 + index(keys(local.instances), each.key)
  }

  volumes {
    volume_name    = docker_volume.n8n_data[each.key].name
    container_path = "/home/node/.n8n"
  }
}

resource "random_password" "n8n_admin_password" {
  length  = 24
  special = false # simpler for CLI usage
}

resource "null_resource" "n8n_admin_user" {
  for_each = local.instances

  triggers = {
    container_id = docker_container.n8n_instances[each.key].id
  }

  provisioner "local-exec" {
    command = <<EOT
      # Wait for n8n to be ready (naive sleep, better to curl healthcheck)
      sleep 30

      # Create admin user
      # We ignore failure in case user already exists (idempotency attempt)
      docker exec ${docker_container.n8n_instances[each.key].name} n8n user:create \
        --email "[email protected]" \
        --firstName "Admin" \
        --lastName "User" \
        --password "${random_password.n8n_admin_password.result}" \
        --role global:owner || true
    EOT
  }
}

output "admin_credentials" {
  value = {
    email    = "[email protected]"
    password = random_password.n8n_admin_password.result
  }
  sensitive = true
}
