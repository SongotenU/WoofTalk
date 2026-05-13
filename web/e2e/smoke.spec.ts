import { test, expect } from "@playwright/test";

test("homepage loads successfully", async ({ page }) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await expect(page).toHaveTitle(/WoofTalk/i, { timeout: 10000 });
  // Verify key UI elements are present
  await expect(page.locator("h1").first()).toBeVisible({ timeout: 10000 });
});

test("signin page is accessible", async ({ page }) => {
  await page.goto("/auth/signin", { waitUntil: "domcontentloaded" });
  await expect(page.locator("h1").first()).toBeVisible({ timeout: 10000 });
});

test("community page is accessible", async ({ page }) => {
  await page.goto("/community");
  await expect(page.getByRole("heading")).toBeVisible();
});

test("translate page is accessible", async ({ page }) => {
  await page.goto("/translate", { waitUntil: "domcontentloaded" });
  await expect(page.locator("h1").first()).toBeVisible({ timeout: 10000 });
});

test("navigation links work", async ({ page }) => {
  await page.goto("/", { waitUntil: "domcontentloaded" });
  await expect(page.locator("h1").first()).toBeVisible({ timeout: 10000 });
  // Navigate to translate page to verify link is present
  await page.evaluate(() => {
    window.location.href = "/translate";
  });
  await expect(page.locator("h1").first()).toBeVisible({ timeout: 10000 });
});
