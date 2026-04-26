const { test, expect } = require('@playwright/test');

test.describe('VAGUS Deep Tests', () => {

  // ── CONSOLE ERROR DETAIL ──────────────────────────────────────
  test('D01 - Capture full console error details', async ({ page }) => {
    const errors = [];
    const warnings = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push({ text: msg.text(), loc: msg.location() });
      }
      if (msg.type() === 'warning') {
        warnings.push(msg.text());
      }
    });
    page.on('pageerror', err => {
      errors.push({ text: err.message, stack: err.stack });
    });
    await page.goto('/');
    await page.waitForTimeout(6000);
    console.log('=== ERRORS ===');
    errors.forEach(e => console.log(JSON.stringify(e)));
    console.log('=== WARNINGS ===');
    warnings.slice(0, 10).forEach(w => console.log(w));
    await page.screenshot({
      path: 'test-results/screenshots/D01-errors.png',
      fullPage: true
    });
    // Save to file for Claude to read
    const fs = require('fs');
    fs.mkdirSync('test-results', { recursive: true });
    fs.writeFileSync('test-results/console-errors.json',
      JSON.stringify({ errors, warnings: warnings.slice(0,20) }, null, 2));
  });

  // ── SPLASH SCREEN ─────────────────────────────────────────────
  test('D02 - Splash screen content and transition', async ({ page }) => {
    await page.goto('/');
    // Capture splash immediately
    await page.waitForTimeout(500);
    await page.screenshot({
      path: 'test-results/screenshots/D02a-splash-immediate.png',
      fullPage: true
    });
    // Wait for splash to finish
    await page.waitForTimeout(5000);
    await page.screenshot({
      path: 'test-results/screenshots/D02b-post-splash.png',
      fullPage: true
    });
    const html = await page.content();
    console.log('Post-splash has login form:',
      html.includes('login') || html.includes('Login') ||
      html.includes('email') || html.includes('Email'));
  });

  // ── AUTH SCREEN ───────────────────────────────────────────────
  test('D03 - Auth screen elements visible', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);
    await page.screenshot({
      path: 'test-results/screenshots/D03a-auth-full.png',
      fullPage: true
    });
    // Try to find interactive elements
    const buttons = page.locator('flt-semantics[role="button"]');
    const buttonCount = await buttons.count();
    console.log('Buttons found on auth screen:', buttonCount);
    // Log all button labels
    for (let i = 0; i < Math.min(buttonCount, 10); i++) {
      const label = await buttons.nth(i).getAttribute('aria-label');
      console.log(`  Button ${i}: ${label}`);
    }
    // Look for text elements
    const allText = page.locator('flt-semantics[aria-label]');
    const textCount = await allText.count();
    console.log('Semantic elements found:', textCount);
    // Sample first 20 semantic labels
    for (let i = 0; i < Math.min(textCount, 20); i++) {
      const label = await allText.nth(i).getAttribute('aria-label');
      if (label && label.trim()) console.log(`  [${i}] ${label}`);
    }
  });

  // ── SIGN UP FLOW ──────────────────────────────────────────────
  test('D04 - Sign up button is tappable', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);
    // Try to find and click sign up
    const signUpBtn = page.getByText('Sign Up', { exact: false });
    const signUpCount = await signUpBtn.count();
    console.log('Sign up elements found:', signUpCount);
    if (signUpCount > 0) {
      await page.screenshot({
        path: 'test-results/screenshots/D04a-before-signup-tap.png'
      });
      await signUpBtn.first().click();
      await page.waitForTimeout(2000);
      await page.screenshot({
        path: 'test-results/screenshots/D04b-after-signup-tap.png'
      });
      console.log('Tapped sign up — screenshot taken');
    } else {
      console.log('Sign up button not found — taking page screenshot');
      await page.screenshot({
        path: 'test-results/screenshots/D04-no-signup-found.png',
        fullPage: true
      });
    }
  });

  // ── FEATURE FLAG GATES ────────────────────────────────────────
  test('D05 - Feature-flagged items are hidden by default', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);
    // These should NOT be visible in default build
    const hiddenFeatures = [
      'Video Call', 'Scan', 'Health Sync',
      'Google Drive', 'Connect Google', 'Upgrade'
    ];
    const found = [];
    const notFound = [];
    for (const feature of hiddenFeatures) {
      const el = page.getByText(feature, { exact: false });
      const count = await el.count();
      if (count > 0) {
        found.push(feature);
      } else {
        notFound.push(feature);
      }
    }
    console.log('Feature-flagged items VISIBLE (should be hidden):', found);
    console.log('Feature-flagged items correctly hidden:', notFound);
    await page.screenshot({
      path: 'test-results/screenshots/D05-feature-flags.png',
      fullPage: true
    });
  });

  // ── RESPONSIVE LAYOUT DEEP ────────────────────────────────────
  test('D06 - Layout at 5 different screen sizes', async ({ page }) => {
    const sizes = [
      { w: 375, h: 812, name: 'iphone-13' },
      { w: 390, h: 844, name: 'iphone-14' },
      { w: 414, h: 896, name: 'iphone-plus' },
      { w: 768, h: 1024, name: 'ipad' },
      { w: 1280, h: 800, name: 'desktop' },
    ];
    for (const size of sizes) {
      await page.setViewportSize({ width: size.w, height: size.h });
      await page.goto('/');
      await page.waitForTimeout(3000);
      await page.screenshot({
        path: `test-results/screenshots/D06-${size.name}.png`,
        fullPage: true
      });
      console.log(`Captured ${size.name} (${size.w}x${size.h})`);
    }
  });

  // ── NAVIGATION ATTEMPT ────────────────────────────────────────
  test('D07 - Try navigating to known routes', async ({ page }) => {
    const routes = [
      '/login', '/signup', '/register',
      '/dashboard', '/home', '/workout',
      '/nutrition', '/settings', '/support'
    ];
    for (const route of routes) {
      await page.goto(route);
      await page.waitForTimeout(2000);
      const title = await page.title();
      const url = page.url();
      await page.screenshot({
        path: `test-results/screenshots/D07-route-${route.replace('/', '')}.png`
      });
      console.log(`Route ${route} → title: "${title}" url: ${url}`);
    }
  });

  // ── PERFORMANCE DEEP ──────────────────────────────────────────
  test('D08 - Measure real performance metrics', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    const metrics = await page.evaluate(() => {
      const nav = performance.getEntriesByType('navigation')[0];
      const paint = performance.getEntriesByType('paint');
      return {
        domContentLoaded: nav?.domContentLoadedEventEnd,
        loadComplete: nav?.loadEventEnd,
        firstPaint: paint.find(p => p.name === 'first-paint')?.startTime,
        firstContentfulPaint: paint.find(
          p => p.name === 'first-contentful-paint'
        )?.startTime,
        transferSize: nav?.transferSize,
        encodedBodySize: nav?.encodedBodySize,
      };
    });
    console.log('Performance metrics:', JSON.stringify(metrics, null, 2));
    await page.screenshot({
      path: 'test-results/screenshots/D08-performance.png'
    });
    const fs = require('fs');
    fs.writeFileSync('test-results/performance.json',
      JSON.stringify(metrics, null, 2));
  });

  // ── ACCESSIBILITY BASICS ──────────────────────────────────────
  test('D09 - Basic accessibility check', async ({ page }) => {
    await page.goto('/');
    await page.waitForTimeout(5000);
    // Count semantic elements
    const semanticEls = await page.locator('flt-semantics').count();
    const buttons = await page.locator(
      'flt-semantics[role="button"]'
    ).count();
    const images = await page.locator(
      'flt-semantics[role="img"]'
    ).count();
    console.log('Semantic elements:', semanticEls);
    console.log('Accessible buttons:', buttons);
    console.log('Accessible images:', images);
    await page.screenshot({
      path: 'test-results/screenshots/D09-accessibility.png'
    });
  });

  // ── DARK THEME ────────────────────────────────────────────────
  test('D10 - App appearance at dark system preference', async ({
    browser
  }) => {
    const context = await browser.newContext({
      colorScheme: 'dark',
      viewport: { width: 390, height: 844 },
    });
    const page = await context.newPage();
    await page.goto('http://localhost:8080');
    await page.waitForTimeout(4000);
    await page.screenshot({
      path: 'test-results/screenshots/D10-dark-mode.png',
      fullPage: true
    });
    console.log('Dark mode screenshot taken');
    await context.close();
  });

});
