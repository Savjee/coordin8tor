import { access } from "node:fs/promises";
import { constants } from "node:fs";
import { resolve } from "node:path";
import { execa } from "execa";

export async function terraformInit(workdir: string): Promise<void> {
  await runTerraform(workdir, ["init", "-backend=false"]);
}

export async function terraformValidate(workdir: string): Promise<void> {
  await runTerraform(workdir, ["validate"]);
}

export async function terraformPlan(workdir: string): Promise<void> {
  await runTerraform(workdir, ["plan"]);
}

export async function terraformApply(workdir: string): Promise<void> {
  await runTerraform(workdir, ["apply"]);
}

export async function terraformDestroy(workdir: string): Promise<void> {
  await runTerraform(workdir, ["destroy"]);
}

export async function checkTerraformAvailable(): Promise<void> {
  await execa("terraform", ["version"], { stdio: "ignore" });
}

export async function checkConfigReadable(configPath: string): Promise<void> {
  const absolutePath = resolve(configPath);
  await access(absolutePath, constants.R_OK);
}

async function runTerraform(workdir: string, args: string[]): Promise<void> {
  await execa("terraform", args, {
    cwd: workdir,
    stdio: "inherit"
  });
}
