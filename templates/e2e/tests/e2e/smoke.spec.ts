import { expect, test } from "@playwright/test";

/**
 * Auth-free smoke: the app boots and renders without a fatal console error.
 *
 * This is the minimal starting point every fullstack repo gets. Replace the
 * landing assertion with something specific to your app (a wordmark, a heading,
 * the main canvas/svg). For auth-gated apps, add seeded-account fixtures —
 * see fixtures.ts.example.
 */

test.describe("smoke", () => {
  test("landing page renders without fatal console errors", async ({ page }) => {
    const fatal: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") fatal.push(msg.text());
    });
    page.on("pageerror", (err) => fatal.push(err.message));

    const response = await page.goto("/");
    expect(response?.ok(), `GET / returned ${response?.status()}`).toBeTruthy();

    // App root mounted (adjust selector to your app shell).
    await expect(page.locator("body")).toBeVisible();

    // No uncaught runtime / console errors during initial render.
    expect(fatal, `console/page errors:\n${fatal.join("\n")}`).toHaveLength(0);
  });
});
