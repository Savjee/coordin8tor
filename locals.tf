locals {
  raw_config = jsondecode(file("${path.module}/instances.json"))

  # Flatten the list of instances into a map for for_each
  instances = {
    for idx, inst in local.raw_config.instances : inst.name => {
      name        = inst.name
      hostname    = inst.hostname
      n8n_version = inst.n8n_version
      image       = try(inst.image, "n8n/n8n:${inst.n8n_version}")

      # Handle custom build logic (if 'build' block exists)
      custom_build = can(inst.build) ? {
        context    = inst.build.context
        dockerfile = inst.build.dockerfile
        args       = try(inst.build.args, {})
      } : null

      auth = {
        allowed_groups = try(inst.auth.allowed_groups, [])
      }
    }
  }
}
