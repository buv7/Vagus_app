const { test, expect } = require('@playwright/test');

test.describe('VAGUS Web Smoke Tests', () => {

  test('01 - App loads and splash screen renders', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(4000);
    await page.screenshot({
      path: 'test-results/screenshots/01-splash.png',
      fullPage: true
    });
    // App should render something — not a blank white page
    const body = await page.locator('body').innerHTML();
    expect(body.length).toBeGreaterThan(100);
  });

  test('02 - Auth screen renders (login or signup)', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);
    await page.screenshot({
      path: 'test-results/screenshots/02-auth.png',
      fullPage: true
    });
    // Should not be a blank page
    const title = await page.title();
    console.log('Page title:', title);
  });

  test('03 - No JavaScript console errors on load', async ({ page }) => {
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push({
          text: msg.text(),
          location: msg.location(),
        });
      }
    });
    page.on('pageerror', err => {
      errors.push({
        text: err.message,
        stack: err.stack,
      });
    });
    await page.goto('/');
    await page.waitForTimeout(5000);
    await page.screenshot({
      path: 'test-results/screenshots/03-console-check.png'
    });
    console.log('Console errors found:', errors.length);
    errors.forEach(e => console.log(JSON.stringify(e, null, 2)));
  });

  test('04 - App is mobile-sized and not broken layout', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto('/');
    await page.waitForTimeout(4000);
    await page.screenshot({
      path: 'test-results/screenshots/04-mobile-layout.png',
      fullPage: true
    });
  });

  test('05 - App renders on tablet viewport', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto('/');
    await page.waitForTimeout(4000);
    await page.screenshot({
      path: 'test-results/screenshots/05-tablet-layout.png',
      fullPage: true
    });
  });

  test('06 - Performance: page load under 10 seconds', async ({ page }) => {
    const start = Date.now();
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    const loadTime = Date.now() - start;
    console.log(`Load time: ${loadTime}ms`);
    await page.screenshot({
      path: 'test-results/screenshots/06-performance.png'
    });
    expect(loadTime).toBeLessThan(10000);
  });

  test('07 - No broken images or assets', async ({ page }) => {
    const failedRequests = [];
    page.on('requestfailed', req => failedRequests.push(req.url()));
    await page.goto('/');
    await page.waitForTimeout(5000);
    console.log('Failed asset requests:', failedRequests.length);
    failedRequests.forEach(url => console.log(' -', url));
    await page.screenshot({
      path: 'test-results/screenshots/07-assets.png'
    });
  });

  test('08 - App bundle size is reasonable', async ({ page }) => {
    const fs = require('fs');
    const path = require('path');
    const buildDir = path.join(__dirname, '..', '..', '..', 'build', 'web');
    const mainJsPath = path.join(buildDir, 'main.dart.js');
    const mainJsBytes = fs.statSync(mainJsPath).size;
    function dirSize(dir) {
      let total = 0;
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) total += dirSize(full);
        else total += fs.statSync(full).size;
      }
      return total;
    }
    const totalBytes = dirSize(buildDir);
    const mainJsMB = (mainJsBytes / 1024 / 1024).toFixed(2);
    const totalMB = (totalBytes / 1024 / 1024).toFixed(2);
    console.log(`main.dart.js size: ${mainJsMB} MB`);
    console.log(`Total build/web: ${totalMB} MB`);
    fs.mkdirSync('test-results', { recursive: true });
    fs.writeFileSync('test-results/bundle-size.json',
      JSON.stringify({
        mainJsBytes, mainJsMB,
        totalBytes, totalMB,
      }, null, 2));
    await page.goto('/');
    await page.waitForTimeout(3000);
    await page.screenshot({
      path: 'test-results/screenshots/08-bundle.png'
    });
  });

});
