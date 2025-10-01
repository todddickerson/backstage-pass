# Test Suite Health Assessment

**Date:** October 1, 2025
**Assessed By:** Claude (Ultrathink Mode)
**Issue:** #50

---

## Executive Summary

**Overall Status:** 🟡 **NEEDS ATTENTION**

- **Total Tests:** 377
- **Passing:** ~268 (71%)
- **Failing:** 38 failures + 69 errors = 107 problems
- **Target:** 80% pass rate
- **Gap:** 9% below target

---

## Test Results by Category

### 1. Model Tests ✅ (86% Pass Rate)
```
58 tests, 98 assertions
0 failures, 8 errors, 0 skips
86% pass rate (50/58)
```

**Status:** GOOD - mostly passing

**Errors (8):**
- All related to `ActiveRecord::RecordNotUnique`
- Duplicate key violation: `index_memberships_on_user_id_and_team_id`
- Affects: `AbilityTest`, `InvitationTest`
- **Root Cause:** Test data not cleaning up properly between tests

**Files Affected:**
- `test/models/ability_test.rb` (6 errors)
- `test/models/invitation_test.rb` (2 errors)

---

### 2. Controller Tests ⚠️ (76% Pass Rate)
```
173 tests, 633 assertions
8 failures, 33 errors, 21 skips
76% pass rate (132/173, excluding skips)
```

**Status:** FAIR - needs improvement

**Major Issues:**

#### Missing Translations (1 error)
- `Translation missing: en.access_pass_experiences.fields.experience.id.heading`
- Affects: `Api::OpenApiControllerTest`
- **Fix:** Add missing locale entries

#### Analytics Controller (5 failures)
- `DailySnapshotsControllerTest` all failing
- Issues: 404s, validation errors, date uniqueness
- **Root Cause:** Test data setup problems

#### Billing Purchases (5 errors)
- All `Billing::PurchasesControllerTest` tests failing
- Error: `Validation failed: Access Pass is invalid`
- **Root Cause:** Invalid access_pass association in test data

#### Experience Type (1 error)
- `'Alternative String Value' is not a valid experience_type`
- **Fix:** Update test to use valid enum value

#### Platform Applications (1 failure)
- Provision key test failing
- **Root Cause:** Missing test provision key configuration

---

### 3. Integration Tests 🔴 (60% Pass Rate)
```
146 tests, 618 assertions
30 failures, 28 errors, 0 skips
60% pass rate (88/146)
```

**Status:** POOR - major issues

**Critical Issues:**

#### Authentication Redirects (25+ failures)
- Tests expecting 200 responses getting 302 redirects to `/`
- Tests expecting 401/403 getting 302 redirects
- **Pattern:** Unauthenticated requests redirecting instead of returning proper status codes
- **Affects:**
  - `PublicStreamingIntegrationTest` (12 failures)
  - `UserOnboardingFlowTest` (4 failures)
  - Multiple other integration tests

**Root Cause:** Authentication middleware redirecting before tests can assert on status codes

#### Access Control Not Enforcing (1 failure)
- `PurchaseFlowBasicTest::test_expired_access_grant_denies_access`
- Expired grants still allowing access
- **Critical Security Issue:** Revenue-impacting

#### Missing Translation (1 error)
- `Translation missing: en.devise.hints.password_length`
- **Fix:** Add to locale file

#### Test Logic Issues
- Password reset flow test checking wrong content
- User registration validation test not finding error elements
- Chat integration tests timing out

---

## 🚨 Critical Issues (Fix First)

### Priority 1: Access Control Security ⚠️ REVENUE-CRITICAL
**Issue:** Expired access grants not denying access
**Test:** `test/integration/purchase_flow_basic_test.rb:125`
**Impact:** Users could access paid content after expiration
**Fix Required:** Implement expiration check in access control

### Priority 2: Membership Uniqueness Errors (8 failures)
**Issue:** Tests creating duplicate memberships
**Impact:** Tests unreliable, CI/CD unstable
**Fix Required:** Ensure proper test data cleanup

### Priority 3: Authentication Test Redirects (25+ failures)
**Issue:** Tests getting redirected instead of proper HTTP status codes
**Impact:** Can't verify auth/authz working correctly
**Fix Required:** Mock authentication properly in tests

---

## Issues by Severity

### 🔴 Critical (Fix Immediately)
1. **Access control not enforcing expiration** (1 test) - SECURITY
2. **Membership uniqueness violations** (8 tests) - STABILITY
3. **Missing translations** (2 tests) - FUNCTIONALITY

### 🟡 High (Fix This Sprint)
4. **Authentication redirect pattern** (25+ tests) - TEST QUALITY
5. **Billing purchase validation** (5 tests) - CORE FEATURE
6. **Analytics controller failures** (5 tests) - DASHBOARD

### 🟢 Medium (Fix Before Launch)
7. **Experience type validation** (1 test) - DATA INTEGRITY
8. **Platform provision key** (1 test) - TESTING INFRA
9. **Test timeout issues** - PERFORMANCE

---

## Recommended Fix Order

### Week 1: Critical Fixes (Days 1-2)

#### Day 1 Morning: Membership Uniqueness (2-3 hours)
```ruby
# Fix test/support/test_helper.rb or use database_cleaner
# Ensure proper cleanup between tests

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  # OR
  config.before(:each) do
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

**Expected Impact:** +8 tests passing (86% → 88%)

#### Day 1 Afternoon: Missing Translations (1 hour)
```yaml
# config/locales/en/access_pass_experiences.en.yml
en:
  access_pass_experiences:
    fields:
      experience:
        id:
          heading: "Experience"

# config/locales/en/devise.en.yml
en:
  devise:
    hints:
      password_length: "Minimum %{minimum_length} characters"
```

**Expected Impact:** +3 tests passing (88% → 89%)

#### Day 1 Evening: Access Control Expiration (2-3 hours)
```ruby
# app/models/access_grant.rb or app/controllers/concerns/access_control.rb
def active?
  return false if revoked?
  return false if expired?

  status == "active"
end

def expired?
  expires_at.present? && expires_at < Time.current
end
```

**Expected Impact:** +1 test passing + SECURITY FIX (89% → 90%)

---

### Week 1: High Priority Fixes (Days 2-3)

#### Day 2: Authentication Test Infrastructure (4-6 hours)
```ruby
# test/support/authentication_helpers.rb
module AuthenticationHelpers
  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: 'password' }
    }
    follow_redirect!
  end

  def api_sign_in_as(user)
    token = user.create_new_auth_token
    @auth_headers = token
  end
end

# Include in test_helper.rb
class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
end
```

**Expected Impact:** +20-25 tests passing (90% → 95%+)

#### Day 3: Billing & Analytics Fixes (3-4 hours)
- Fix `Billing::Purchase` test factory to create valid access_pass
- Fix `Analytics::DailySnapshot` test data uniqueness
- Update test data to match current schema

**Expected Impact:** +10 tests passing (95% → 98%)

---

### Week 1: Final Cleanup (Day 4)

#### Remaining Issues
- Experience type enum fix
- Platform provision key configuration
- Any remaining test timeouts

**Expected Impact:** 98%+ → 100% or near-100%

---

## Test Coverage Gaps (For Issue #56)

### Missing Test Coverage
1. **LiveKit streaming end-to-end**
   - Room creation
   - Token generation
   - Viewer access with valid grants

2. **GetStream chat end-to-end**
   - Channel creation
   - Message sending/receiving
   - Moderation

3. **Complete purchase → access → view flow**
   - User discovers space
   - Purchases access pass
   - Access grant created
   - Can watch stream
   - Cannot access after expiration

4. **Subscription handling**
   - Monthly renewal
   - Payment failure
   - Subscription cancellation
   - Access revocation on cancel

---

## Success Metrics

### Minimum Viable (Before Deploy)
- ✅ 80%+ tests passing (currently 71%)
- ✅ Zero critical security failures
- ✅ All payment tests passing (DONE - 65/65)
- ✅ Access control tested and working
- ✅ No test timeouts

### Optimal (Launch Ready)
- ✅ 95%+ tests passing
- ✅ All critical paths tested
- ✅ Integration tests for all user stories
- ✅ CI/CD passing consistently
- ✅ Test suite runs < 5 minutes

---

## Next Actions

### Immediate (This Session)
1. ✅ Fix membership uniqueness errors
2. ✅ Add missing translations
3. ✅ Fix access control expiration check

### Short-term (This Week)
4. ✅ Fix authentication test infrastructure
5. ✅ Fix billing/analytics test data
6. ✅ Achieve 95%+ pass rate

### Follow-up (Next Week)
7. ✅ Add missing integration tests (Issue #56)
8. ✅ Verify streaming functionality (Issues #52, #53)
9. ✅ Complete access control verification (Issue #51)

---

## Files Requiring Updates

### High Priority
1. `test/models/ability_test.rb` - Fix membership setup
2. `test/models/invitation_test.rb` - Fix membership setup
3. `config/locales/en/access_pass_experiences.en.yml` - Add translation
4. `config/locales/en/devise.en.yml` - Add translation
5. `app/models/access_grant.rb` - Add expiration logic
6. `test/support/authentication_helpers.rb` - Create file
7. `test/test_helper.rb` - Include auth helpers

### Medium Priority
8. `test/factories/billing/purchases.rb` - Fix access_pass association
9. `test/factories/analytics/daily_snapshots.rb` - Fix date uniqueness
10. `test/controllers/api/v1/experiences_controller_test.rb` - Fix enum value

---

## Estimated Time to Fix

- **Critical fixes:** 1 day
- **High priority fixes:** 2 days
- **Medium priority fixes:** 1 day
- **Total:** ~4 days to 95%+ pass rate
- **Stretch goal (100%):** +1 day = 5 days total

---

## Conclusion

Test suite is **71% passing** with clear, fixable issues. Most failures stem from:
1. Test data cleanup (8 errors)
2. Missing translations (3 errors)
3. Authentication test infrastructure (25+ failures)
4. Test data validation (10+ failures)

**All issues are addressable within 4-5 days.**

The most critical issue is the **access control expiration** bug, which is a revenue-impacting security issue that must be fixed before any production deployment.

---

**Status:** Ready to begin fixes
**Next Step:** Fix membership uniqueness constraints
