# 1. Main Postgres Database (Local Docker)
resource "docker_image" "postgres" {
  name = "postgres:14-alpine"
}

# Generate init.sql based on configuration
resource "local_file" "postgres_init" {
  filename = "${path.module}/docker/postgres-init/init.sql"
  content  = join("\n", [
    for key, inst in local.instances : <<EOF
-- Create User and DB for ${inst.name}
CREATE USER "${inst.hostname}" WITH PASSWORD 'password_${inst.hostname}';
CREATE DATABASE "${inst.hostname}" OWNER "${inst.hostname}";
GRANT ALL PRIVILEGES ON DATABASE "${inst.hostname}" TO "${inst.hostname}";
EOF
  ])
}

resource "docker_container" "postgres" {
  name  = "coordin8tor-postgres"
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_PASSWORD=mysecretpassword",
    "POSTGRES_USER=postgres",
    "POSTGRES_DB=postgres"
  ]

  ports {
    internal = 5432
    external = 5432
  }

  volumes {
    host_path      = abspath(local_file.postgres_init.filename)
    container_path = "/docker-entrypoint-initdb.d/init.sql"
  }
}

# 2. n8n Instances
resource "docker_image" "n8n_images" {
  for_each = local.instances

  name = each.value.custom_build != null ? "custom-n8n-${each.key}:${each.value.n8n_version}" : each.value.image

  dynamic "build" {
    for_each = each.value.custom_build != null ? [each.value.custom_build] : []
    content {
      context    = build.value.context
      dockerfile = build.value.dockerfile
      build_args = merge(
        { N8N_VERSION = each.value.n8n_version },
        build.value.args
      )
      tag = ["custom-n8n-${each.key}:${each.value.n8n_version}"]
    }
  }
}

resource "random_password" "n8n_encryption_key" {
  for_each = local.instances
  length   = 24
  special  = true
}

resource "docker_container" "n8n_instances" {
  for_each = local.instances

  name  = "n8n-${each.value.hostname}"
  image = docker_image.n8n_images[each.key].image_id

  env = [
    "DB_TYPE=postgresdb",
    "DB_POSTGRESDB_HOST=host.docker.internal", # Local dev networking
    "DB_POSTGRESDB_PORT=5432",
    "DB_POSTGRESDB_DATABASE=${each.value.hostname}",
    "DB_POSTGRESDB_USER=${each.value.hostname}",
    "DB_POSTGRESDB_PASSWORD=password_${each.value.hostname}",

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

  depends_on = [docker_container.postgres]
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
      docker exec n8n-${each.value.hostname} n8n user:create \
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
