const { test, expect } = require('@playwright/test');
const fs = require('fs');

test.describe('VAGUS Post-Fix Validation', () => {

  test('PF01 - No startup console errors', async ({ page }) => {
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push({ text: msg.text(), loc: msg.location() });
      }
    });
    page.on('pageerror', err => {
      errors.push({ text: err.message, stack: err.stack });
    });
    await page.goto('/');
    await page.waitForTimeout(6000);
    fs.mkdirSync('test-results', { recursive: true });
    fs.writeFileSync(
      'test-results/post-fix-errors.json',
      JSON.stringify(errors, null, 2)
    );
    console.log('Startup errors after fix:', errors.length);
    errors.forEach(e => console.log(JSON.stringify(e)));
    expect(errors.length).toBe(0);
  });

  test('PF02 - Semantics tree is populated', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(6000);
    const semanticCount = await page.locator('flt-semantics').count();
    console.log('flt-semantics nodes:', semanticCount);
    fs.mkdirSync('test-results/screenshots', { recursive: true });
    await page.screenshot({
      path: 'test-results/screenshots/PF02-semantics.png'
    });
    expect(semanticCount).toBeGreaterThan(0);
  });

  test('PF03 - Can find interactive elements by label', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(6000);
    const buttons = page.locator('flt-semantics[role="button"]');
    const count = await buttons.count();
    console.log('Accessible buttons found:', count);
    for (let i = 0; i < Math.min(count, 15); i++) {
      const label = await buttons.nth(i).getAttribute('aria-label');
      console.log(`  Button [${i}]: ${label}`);
    }
    fs.mkdirSync('test-results/screenshots', { recursive: true });
    await page.screenshot({
      path: 'test-results/screenshots/PF03-buttons.png'
    });
    expect(count).toBeGreaterThan(0);
  });

  test('PF04 - SPA routing works (dashboard route)', async ({ page }) => {
    const response = await page.goto('/dashboard');
    console.log('Status for /dashboard:', response?.status());
    const title = await page.title();
    console.log('Title:', title);
    fs.mkdirSync('test-results/screenshots', { recursive: true });
    await page.screenshot({
      path: 'test-results/screenshots/PF04-spa-routing.png'
    });
    expect(response?.status()).not.toBe(404);
  });

  test('PF05 - Feature flags: calling button hidden', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(6000);
    const callingBtn = page.locator(
      'flt-semantics[aria-label*="Call"], flt-semantics[aria-label*="Video"]'
    );
    const count = await callingBtn.count();
    console.log('Calling buttons visible:', count);
    fs.mkdirSync('test-results/screenshots', { recursive: true });
    await page.screenshot({
      path: 'test-results/screenshots/PF05-calling-flag.png'
    });
    expect(count).toBe(0);
  });

});
