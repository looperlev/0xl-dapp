/**
 * Load `.env` from the project root (one level above `server/`), not from `process.cwd()`.
 * Ensures OXL_*, JWT_SECRET, DATABASE_URL, etc. are available when the server or tests
 * are started from a different working directory, or when modules load in another order.
 */
import { existsSync } from "node:fs";
import { config } from "dotenv";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const _dir = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(_dir, "..", "..");
const envFile = join(projectRoot, ".env");
const exampleFile = join(projectRoot, ".env.example");

if (!existsSync(envFile) && existsSync(exampleFile)) {
  console.warn(
    "[loadEnv] No .env file in the project root. The app only loads .env, not .env.example.\n" +
      "  Create it:  copy .env.example .env   (Windows)   or   cp .env.example .env   (macOS/Linux)\n" +
      "  Then put your real OXL_API_KEY and other secrets in .env .",
  );
}

config({ path: envFile });
