locals {
  resource_prefix = "coordin8tor-"
  raw_config      = jsondecode(file("${path.module}/instances.json"))

  # Flatten the list of instances into a map for for_each
  instances = {
    for idx, inst in local.raw_config.instances : inst.name => {
      name        = inst.name
      hostname    = inst.hostname
      n8n_version = inst.n8n_version
      image       = "${try(inst.image, "n8nio/n8n")}:${inst.n8n_version}"

      auth = {
        allowed_groups = try(inst.auth.allowed_groups, [])
      }
    }
  }
}
