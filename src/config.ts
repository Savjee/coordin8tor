import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { z } from "zod";

const authSchema = z.object({
  allowed_groups: z.array(z.string().min(1)).min(1)
});

const instanceSchema = z.object({
  name: z.string().min(1),
  hostname: z.string().min(1),
  n8n_version: z.string().min(1),
  image: z.string().min(1).optional(),
  auth: authSchema.optional()
});

const instancesConfigSchema = z.object({
  instances: z.array(instanceSchema).min(1)
});

export type InstancesConfig = z.infer<typeof instancesConfigSchema>;

export async function loadAndValidateConfig(configPath: string): Promise<{
  config: InstancesConfig;
  absolutePath: string;
}> {
  const absolutePath = resolve(configPath);
  const raw = await readFile(absolutePath, "utf-8");
  const parsed = JSON.parse(raw) as unknown;
  const config = instancesConfigSchema.parse(parsed);

  return { config, absolutePath };
}
