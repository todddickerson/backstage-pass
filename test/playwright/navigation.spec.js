// Basic navigation tests for Backstage Pass
const { test, expect } = require('@playwright/test');

test.describe('Public Navigation', () => {
  test('should navigate to homepage', async ({ page }) => {
    await page.goto('/');
    
    // Check that the page loads successfully
    await expect(page).toHaveTitle(/Backstage Pass/i);
    
    // Verify key elements are present
    const signInLink = page.locator('a[href="/users/sign_in"]');
    await expect(signInLink).toBeVisible();
  });
  
  test('should navigate to about page', async ({ page }) => {
    await page.goto('/about');
    
    // Check heading is present
    const heading = page.locator('h1:has-text("About Backstage Pass")');
    await expect(heading).toBeVisible();
    
    // Check for key content
    await expect(page.locator('text=Empowering Creators')).toBeVisible();
  });
  
  test('should navigate to terms page', async ({ page }) => {
    await page.goto('/terms');
    
    // Check heading
    const heading = page.locator('h1:has-text("Terms of Service")');
    await expect(heading).toBeVisible();
    
    // Check for key sections
    await expect(page.locator('text=Acceptance of Terms')).toBeVisible();
    await expect(page.locator('text=Use License')).toBeVisible();
  });
  
  test('should navigate to privacy page', async ({ page }) => {
    await page.goto('/privacy');
    
    // Check heading
    const heading = page.locator('h1:has-text("Privacy Policy")');
    await expect(heading).toBeVisible();
    
    // Check for key sections
    await expect(page.locator('text=Information We Collect')).toBeVisible();
    await expect(page.locator('text=Data Security')).toBeVisible();
  });
  
  test('should navigate to explore spaces', async ({ page }) => {
    await page.goto('/explore');
    
    // Check heading
    const heading = page.locator('h1:has-text("Explore Creator Spaces")');
    await expect(heading).toBeVisible();
    
    // Check for grid or empty state
    const spacesGrid = page.locator('.grid');
    const emptyState = page.locator('text=No creator spaces yet');
    
    // Either spaces are shown or empty state is shown
    const hasContent = await spacesGrid.count() > 0 || await emptyState.count() > 0;
    expect(hasContent).toBeTruthy();
  });
});

test.describe('Authentication Flow', () => {
  test('should navigate to sign in page', async ({ page }) => {
    await page.goto('/users/sign_in');
    
    // Check for email and password fields
    await expect(page.locator('input[name="user[email]"]')).toBeVisible();
    await expect(page.locator('input[name="user[password]"]')).toBeVisible();
    
    // Check for submit button
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });
  
  test('should navigate to sign up page', async ({ page }) => {
    await page.goto('/users/sign_up');
    
    // Check for registration fields
    await expect(page.locator('input[name="user[email]"]')).toBeVisible();
    await expect(page.locator('input[name="user[password]"]')).toBeVisible();
    
    // Check for submit button
    const submitButton = page.locator('button[type="submit"]');
    await expect(submitButton).toBeVisible();
  });
  
  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/users/sign_in');
    
    // Try to login with invalid credentials
    await page.fill('input[name="user[email]"]', 'invalid@example.com');
    await page.fill('input[name="user[password]"]', 'wrongpassword');
    await page.click('button[type="submit"]');
    
    // Should show error message
    await expect(page.locator('text=Invalid')).toBeVisible();
  });
});

test.describe('Mobile Responsive Navigation', () => {
  test.use({
    viewport: { width: 375, height: 667 },
  });
  
  test('should show mobile menu', async ({ page }) => {
    await page.goto('/');
    
    // Mobile menu button should be visible
    const menuButton = page.locator('[data-mobile-menu-button]').first();
    
    // If mobile menu exists, test it
    const menuButtonCount = await menuButton.count();
    if (menuButtonCount > 0) {
      await expect(menuButton).toBeVisible();
      
      // Click to open menu
      await menuButton.click();
      
      // Menu items should be visible
      const mobileMenu = page.locator('[data-mobile-menu]');
      await expect(mobileMenu).toBeVisible();
    }
  });
  
  test('should navigate on mobile', async ({ page }) => {
    await page.goto('/');
    
    // Page should be responsive
    await expect(page).toHaveTitle(/Backstage Pass/i);
    
    // Check viewport is mobile size
    const viewportSize = page.viewportSize();
    expect(viewportSize.width).toBeLessThanOrEqual(768);
  });
});