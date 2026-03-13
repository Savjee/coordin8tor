#!/usr/bin/env node
import { Command } from "commander";
import { dirname, resolve } from "node:path";
import { ZodError } from "zod";
import { loadAndValidateConfig } from "./config.js";
import {
  checkConfigReadable,
  checkTerraformAvailable,
  terraformApply,
  terraformDestroy,
  terraformInit,
  terraformPlan,
  terraformValidate
} from "./terraform.js";

type CommandOptions = {
  config: string;
};

const program = new Command();

program
  .name("coordin8tor")
  .description("Thin wrapper around Terraform for Coordin8tor")
  .version("0.1.0");

program
  .command("validate")
  .description("Validate instances.json and terraform configuration")
  .option("-c, --config <path>", "Path to instances config file", "instances.json")
  .action(async (options: CommandOptions) => {
    const { workdir } = await validateConfig(options.config);
    await terraformInit(workdir);
    await terraformValidate(workdir);
    console.log("Configuration and Terraform validation passed.");
  });

program
  .command("plan")
  .description("Run terraform plan after validating config")
  .option("-c, --config <path>", "Path to instances config file", "instances.json")
  .action(async (options: CommandOptions) => {
    const { workdir } = await validateConfig(options.config);
    await terraformInit(workdir);
    await terraformPlan(workdir);
  });

program
  .command("apply")
  .description("Run terraform apply after validating config")
  .option("-c, --config <path>", "Path to instances config file", "instances.json")
  .action(async (options: CommandOptions) => {
    const { workdir } = await validateConfig(options.config);
    await terraformInit(workdir);
    await terraformApply(workdir);
  });

program
  .command("destroy")
  .description("Run terraform destroy after validating config")
  .option("-c, --config <path>", "Path to instances config file", "instances.json")
  .action(async (options: CommandOptions) => {
    const { workdir } = await validateConfig(options.config);
    await terraformInit(workdir);
    await terraformDestroy(workdir);
  });

program
  .command("doctor")
  .description("Check local prerequisites")
  .option("-c, --config <path>", "Path to instances config file", "instances.json")
  .action(async (options: CommandOptions) => {
    await checkTerraformAvailable();
    await checkConfigReadable(options.config);
    console.log("Terraform is available and config file is readable.");
  });

async function validateConfig(configPath: string): Promise<{ workdir: string }> {
  await checkTerraformAvailable();
  const { absolutePath, config } = await loadAndValidateConfig(configPath);
  const workdir = dirname(resolve(absolutePath));
  console.log(`Validated ${config.instances.length} instance(s) in ${absolutePath}.`);
  return { workdir };
}

async function main(): Promise<void> {
  try {
    await program.parseAsync(process.argv);
  } catch (error) {
    if (error instanceof ZodError) {
      console.error("Config validation failed:");
      for (const issue of error.issues) {
        const path = issue.path.join(".") || "(root)";
        console.error(`- ${path}: ${issue.message}`);
      }
      process.exit(1);
    }

    if (error instanceof Error) {
      console.error(error.message);
    } else {
      console.error("Unknown error.");
    }
    process.exit(1);
  }
}

void main();
