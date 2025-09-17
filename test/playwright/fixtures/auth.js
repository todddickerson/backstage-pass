// Authentication fixtures for Playwright tests
const { test: base, expect } = require('@playwright/test');

// Extend base test with authentication helpers
exports.test = base.extend({
  // Authenticated page fixture
  authenticatedPage: async ({ page, baseURL }, use) => {
    // Navigate to login page
    await page.goto('/users/sign_in');
    
    // Fill in login credentials (using test user)
    await page.fill('input[name="user[email]"]', 'test@example.com');
    await page.fill('input[name="user[password]"]', 'password123');
    
    // Submit login form
    await page.click('button[type="submit"]');
    
    // Wait for redirect to dashboard or home
    await page.waitForURL(/\/account|\/dashboard/, { timeout: 10000 });
    
    // Use the authenticated page in tests
    await use(page);
    
    // Cleanup: Sign out after test
    await page.goto('/users/sign_out');
  },
  
  // Creator authenticated page fixture
  creatorPage: async ({ page, baseURL }, use) => {
    // Navigate to login page
    await page.goto('/users/sign_in');
    
    // Fill in creator credentials
    await page.fill('input[name="user[email]"]', 'creator@example.com');
    await page.fill('input[name="user[password]"]', 'password123');
    
    // Submit login form
    await page.click('button[type="submit"]');
    
    // Wait for redirect
    await page.waitForURL(/\/account|\/dashboard/, { timeout: 10000 });
    
    // Use the authenticated page in tests
    await use(page);
    
    // Cleanup: Sign out after test
    await page.goto('/users/sign_out');
  },
});

exports.expect = expect;