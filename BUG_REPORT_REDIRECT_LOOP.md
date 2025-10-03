# 🐛 Critical Bug Report: Redirect Loop in User Flow

**Date**: 2025-10-01
**Reporter**: Claude (Automated Testing)
**Severity**: 🔴 CRITICAL - Blocks Golden Path
**Status**: Requires Investigation

## Executive Summary

Discovered a **redirect loop bug** (ERR_TOO_MANY_REDIRECTS) that prevents users from accessing authenticated pages after completing registration and onboarding. This completely blocks the golden path testing flow.

## Bug Details

### Primary Issue
- **Error**: `ERR_TOO_MANY_REDIRECTS`
- **Trigger**: Clicking "Add New Experience" link from Space show page
- **Impact**: Users cannot proceed past Space management to create Experiences
- **Affected Flow**: Registration → Onboarding → Space Management → **[BLOCKED]** → Experience Creation

### Secondary Issue
- **Error**: "Space not found" message displayed on Space show page
- **Route**: `/account/spaces/22`
- **Impact**: Confusing UX, but page remains functional

### Route Issue Found
- **Missing Route**: `/account/teams/:team_id/spaces/:id` (GET) for show action
- **Existing Route**: `/account/spaces/:id` (works correctly)
- **Impact**: Broken breadcrumb links, inconsistent routing patterns

## User Flow Testing Results

### ✅ Successful Steps

1. **Homepage Load** (Screenshot 01)
   - URL: `https://bsp.ngrok.app/`
   - Status: ✅ Loaded correctly
   - Redirects to sign-in as expected

2. **User Registration** (Screenshots 02-03)
   - Created user: `creator@test.com`
   - Status: ✅ Registration successful
   - User ID: 27 created

3. **Onboarding Flow** (Screenshots 04-06)
   - Completed profile: "Test Creator"
   - Team: "Test Creator Team" (ID: 22)
   - Timezone: "Eastern Time (US & Canada)"
   - Status: ✅ Onboarding completed

4. **Space Creation** (Screenshots 07-13)
   - Auto-created space: "Your Team's Space"
   - Slug: "your-team"
   - Published: ❌ Initially NO → ✅ Updated to YES
   - Status: ✅ Space published successfully

### 🔴 Blocked Steps

5. **Experience Creation** (Screenshots 14-20)
   - Clicked "Add New Experience"
   - Result: ❌ **ERR_TOO_MANY_REDIRECTS**
   - Status: 🔴 BLOCKED - Cannot proceed

## Screenshots Evidence

| # | Screenshot | Description | Status |
|---|------------|-------------|--------|
| 01 | `01_homepage_backstage_pass` | Sign-in page | ✅ |
| 02-03 | `02-03_registration` | Registration form | ✅ |
| 04-06 | `04-06_onboarding` | Profile completion | ✅ |
| 07 | `07_dashboard` | Dashboard showing "Add New Space" | ✅ |
| 08-11 | `08-11_space_creation` | Space creation flow | ✅ |
| 12-13 | `12-13_publish_space` | Publishing space | ✅ |
| 14-15 | `14-15_redirect_error` | Redirect loop error | 🔴 |
| 16-17 | `16-17_sign_in_retry` | Attempted sign-in retry | 🔴 |
| 18-19 | `18-19_space_show` | Space page with error | ⚠️ |
| 20 | `20_experience_redirect` | Final redirect loop | 🔴 |

## Technical Analysis

### User State (Verified via Rails Console)
```json
{
  "id": 27,
  "email": "creator@test.com",
  "first_name": "Test",
  "last_name": "Creator",
  "time_zone": "Eastern Time (US & Canada)",
  "current_team_id": 22,
  "sign_in_count": 2
}
```

**Onboarding Status**: ✅ All required fields populated

### Server Logs Analysis

**Registration Flow** (Working):
```
Processing by RegistrationsController#create
User Create: creator@test.com
Team Create: "Your Team" (ID: 22)
Space Create: "Your Team's Space" (ID: 22, published: FALSE)
Redirected to https://bsp.ngrok.app/account
```

**Redirect Loop Pattern** (Broken):
```
GET "/account/teams/22/spaces/22/experiences/new"
→ Redirects (likely to onboarding check)
→ Redirects back
→ Redirects (loop continues)
→ ERR_TOO_MANY_REDIRECTS
```

### Root Cause Hypothesis

1. **Onboarding Guard Missing Context**
   - Bullet Train's `ensure_onboarding_is_complete` may be checking incorrect state
   - User HAS completed onboarding (first_name, last_name, time_zone all set)
   - But guard may be checking a different condition

2. **Session State Issue**
   - Browser cookies may not be persisting authentication correctly
   - ngrok proxy may be interfering with session handling

3. **Missing Onboarding Method**
   - Attempted to call `user.onboarding_completed?` → method doesn't exist
   - Bullet Train may use different method name (needs investigation)

## Recommended Fixes

### Immediate Actions Required

1. **Investigate Onboarding Guard**
   ```bash
   # Check Bullet Train's onboarding logic
   bin/resolve Account::Onboarding::UserDetailsController --open

   # Look for ensure_onboarding_is_complete method
   grep -r "ensure_onboarding" app/controllers
   ```

2. **Check User Onboarding Method**
   ```ruby
   # Find the actual method Bullet Train uses
   User.instance_methods.grep(/onboard/)
   ```

3. **Fix Route Consistency**
   ```ruby
   # Add missing nested route in config/routes.rb
   namespace :account do
     resources :teams do
       resources :spaces, only: [:show] # Add show action
     end
   end
   ```

4. **Debug Session Persistence**
   ```ruby
   # Add logging to ApplicationController
   before_action :log_session_state, if: -> { Rails.env.development? }

   def log_session_state
     Rails.logger.debug "Session User: #{current_user&.id}, Onboarding: #{current_user&.onboarding_complete?}"
   end
   ```

### Testing Strategy

1. **Unit Test Onboarding Logic**
   ```ruby
   test "user with all required fields passes onboarding" do
     user = users(:with_complete_profile)
     assert user.onboarding_complete?
   end
   ```

2. **System Test Happy Path**
   ```ruby
   test "creator can create experience after onboarding" do
     sign_in_as(users(:creator))
     visit account_space_path(@space)
     click_on "Add New Experience"
     assert_current_path new_account_space_experience_path(@space)
   end
   ```

## Impact Assessment

- **Users Affected**: ALL new users completing registration
- **Business Impact**: 🔴 CRITICAL - Prevents core creator workflow
- **Workaround Available**: ❌ NO - Complete blocker
- **Data Loss Risk**: ✅ None (registration data persists correctly)

## Next Steps

1. [ ] Eject Bullet Train onboarding controllers for debugging
2. [ ] Add comprehensive logging to onboarding flow
3. [ ] Fix session persistence with ngrok
4. [ ] Add missing nested routes
5. [ ] Create regression tests for onboarding completion
6. [ ] Verify fix with full golden path test

## Related Issues

- Missing route: `/account/teams/:team_id/spaces/:id`
- "Space not found" error on valid Space page
- Sign-in form not submitting via Playwright (possible Turbo/JS issue)

---

**Generated by**: Claude Code Automated Testing
**Test Environment**: Development (ngrok + Rails 8.0.2.1)
**All screenshots saved to**: `/Users/todddickerson/Downloads/`
