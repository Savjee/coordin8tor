# Coordin8tor

Coordin8tor orchestrates and manages multiple instances of n8n. It spawns a new Docker container per instance with a specific version of n8n and configures Cloudflare Access for seamless SSO integration.

## TODO

- [] Add support for "latest" version of n8n

## Configuration

Edit `instances.json` to define your instances:

```json
{
  "instances": [
    {
      "name": "My Project",
      "hostname": "my-project",
      "n8n_version": "1.2.3",
      "image": "n8n/n8n",
      "auth": {
        "allowed_groups": ["azure-group-id"]
      }
    },
    {
      "name": "Custom Project",
      "hostname": "custom-project",
      "n8n_version": "1.5.0",
      "build": {
        "context": "./docker/custom-n8n",
        "dockerfile": "Dockerfile"
      }
    }
  ]
}
```

## Local Development

1.  **Init Terraform**:
    ```bash
    terraform init
    ```

2.  **Plan & Apply**:
    ```bash
    terraform apply
    ```
    This will:
    *   Start a Postgres container.
    *   Create a Database and User for each instance.
    *   Build any custom Docker images.
    *   Start an n8n container for each instance.

3.  **Access**:
    *   Instances will be available at `http://localhost:<port>` (ports are assigned starting from 5679).
    *   Check `docker ps` to see the assigned ports.

## Architecture

*   **`instances.json`**: Single source of truth.
*   **`main.tf`**: Terraform logic.
*   **`docker/`**: Custom Dockerfiles and init scripts.
