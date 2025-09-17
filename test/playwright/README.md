# Playwright E2E Tests

End-to-end tests for Backstage Pass using Playwright.

## Setup

1. Install Playwright browsers (one-time setup):
```bash
yarn playwright:install
```

2. Set up test database:
```bash
bin/rails db:test:prepare
```

3. Create test users (if needed):
```bash
bin/rails console -e test
# Create test users as needed
```

## Running Tests

### Run all tests
```bash
yarn test:playwright
```

### Run tests with UI mode (interactive)
```bash
yarn test:playwright:ui
```

### Run tests in headed mode (see browser)
```bash
yarn test:playwright:headed
```

### Run specific test file
```bash
yarn playwright test test/playwright/navigation.spec.js
```

### Run tests in specific browser
```bash
yarn playwright test --project=chromium
yarn playwright test --project=firefox
yarn playwright test --project=webkit
```

## Test Structure

- `navigation.spec.js` - Basic public page navigation tests
- `creator-economy.spec.js` - Creator and monetization workflow tests
- `fixtures/auth.js` - Authentication helpers and fixtures

## Writing Tests

### Basic Test
```javascript
test('should do something', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveTitle(/Backstage Pass/);
});
```

### Authenticated Test
```javascript
const { test } = require('./fixtures/auth');

test('should access protected page', async ({ authenticatedPage }) => {
  await authenticatedPage.goto('/account/dashboard');
  // Test authenticated features
});
```

## Environment Variables

- `PLAYWRIGHT_BASE_URL` - Base URL for tests (default: http://localhost:3000)
- `CI` - Set to true in CI environments

## Mobile Testing

Tests include mobile viewports for responsive testing:
- Mobile Chrome (Pixel 5)
- Mobile Safari (iPhone 12)

## Debugging

### Take screenshots on failure
Screenshots are automatically taken on test failure and stored in `test-results/`.

### Enable trace viewer
```bash
yarn playwright test --trace on
```

### View test report
```bash
yarn playwright show-report
```

## CI Integration

The configuration is set up for CI with:
- Retry failed tests (2 attempts)
- Single worker to avoid race conditions
- Automatic Rails test server startup

## Troubleshooting

### Browser not installed
Run `yarn playwright:install` to install browsers.

### Port already in use
The test server uses port 3001. Make sure it's available or update `playwright.config.js`.

### Database issues
Ensure test database is migrated: `bin/rails db:test:prepare`