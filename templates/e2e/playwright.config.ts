import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright E2E configuration (chrysa fullstack standard — local dev).
 *
 * Tests target the production-like docker stack started by `make docker-up`.
 * Set the default port below to your stack's frontend port (the nginx/Vite
 * service exposed by docker-compose, e.g. discordium 9101, portfolio-viz 8080).
 *
 * E2E_BASE_URL is overridable so the same suite can later run against staging
 * or read-only prod smoke checks without editing this file.
 *
 * Run with `make e2e` (Playwright runs inside the official docker image — never
 * on the host). The stack must be up first.
 */

const baseURL = process.env.E2E_BASE_URL ?? "http://localhost:8080"; // adjust port to your stack · no-hardcoded-localhost: disable

export default defineConfig({
  testDir: "./tests/e2e",
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? "github" : "list",
  use: {
    baseURL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
