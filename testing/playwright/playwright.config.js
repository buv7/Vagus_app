const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  timeout: 30000,
  webServer: {
    command: 'npx http-server ../../build/web -p 8080 --proxy http://localhost:8080?',
    port: 8080,
    reuseExistingServer: true,
    timeout: 10000,
  },
  use: {
    headless: true,
    viewport: { width: 390, height: 844 },
    screenshot: 'on',
    video: 'retain-on-failure',
    baseURL: 'http://localhost:8080',
  },
  reporter: [
    ['list'],
    ['json', { outputFile: 'test-results/results.json' }],
    ['html', { outputFolder: 'test-results/html', open: 'never' }],
  ],
});
