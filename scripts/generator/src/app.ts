import fs from "fs"; // Filesystem
import path from "path"; // Path routing

import Generator from "./generator"; // Generator
import { logger } from "./utils/logger"; // Logging

interface Config {
  decimals?: 18;
  airdrop: Record<string, number>;
}

// Config file path
const configPath = path.join(__dirname, "../config.json");

/**
 * Throws error and exists process
 * @param {string} error to log
 */
function exit(error: string): void {
  logger.error(error);
  process.exit(1);
}

(async () => {
  // Check if config exists
  if (!fs.existsSync(configPath)) {
    return exit("Missing config.json. Please add.");
  }

  // Read config
  const config = fs.readFileSync(configPath).toString();
  const { decimals = 18, airdrop = {} } = JSON.parse(config) as Config;

  // Check if config contains airdrop key
  if (Object.keys(airdrop).length === 0) {
    return exit("Nothing to airdrop. Please add airdrop key in config.");
  }

  // Initialize and call generator
  const generator = new Generator(decimals, airdrop);
  await generator.process();
})();
