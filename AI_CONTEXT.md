# Current Task Context

## 🎯 Working on Issue #21

### Title: STORY 17: Security Hardening - Production Security Checklist

### Description:
**User Story**: As a platform operator I want the application to be secure so that user data is protected

**Acceptance Criteria:**
- [ ] All OWASP Top 10 vulnerabilities addressed
- [ ] Security headers configured
- [ ] Input validation on all forms
- [ ] SQL injection prevention verified
- [ ] XSS protection enabled
- [ ] CSRF tokens properly implemented
- [ ] Rate limiting on all endpoints
- [ ] Secure session management
- [ ] Encrypted sensitive data
- [ ] Security audit passed

**Security Checklist:**

### Authentication & Authorization:
- [ ] Strong password requirements (handled by Devise)
- [ ] Account lockout after failed attempts
- [ ] Session timeout configured
- [ ] Secure password reset flow
- [ ] Two-factor authentication (optional)
- [ ] OAuth providers secured
- [ ] API token rotation

### Data Protection:
- [ ] PII encrypted at rest
- [ ] SSL/TLS enforced (force_ssl)
- [ ] Secure cookies (httponly, secure, samesite)
- [ ] Database encryption for sensitive fields
- [ ] File upload validation
- [ ] S3 bucket policies configured
- [ ] Backup encryption

### Security Headers:
```ruby
# config/application.rb
config.force_ssl = true

# Security headers middleware
config.middleware.use Rack::Protection
config.middleware.use SecureHeaders::Middleware

SecureHeaders::Configuration.default do |config|
  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]
  
  config.csp = {
    default_src: %w['self'],
    font_src: %w['self' data:],
    img_src: %w['self' data: https:],
    script_src: %w['self' 'unsafe-inline'],
    style_src: %w['self' 'unsafe-inline'],
    connect_src: %w['self' wss: https:]
  }
end
```

### Input Validation:
- [ ] Sanitize all user input
- [ ] Parameterized queries only
- [ ] File type validation for uploads
- [ ] Size limits on uploads
- [ ] Rate limiting on forms
- [ ] CAPTCHA on public forms

### API Security:
- [ ] API authentication required
- [ ] Rate limiting per API key
- [ ] Request signing for webhooks
- [ ] CORS properly configured
- [ ] GraphQL query depth limiting
- [ ] API versioning strategy

### Infrastructure Security:
- [ ] Environment variables for secrets
- [ ] No secrets in code repository
- [ ] Database connection encryption
- [ ] Redis password protected
- [ ] VPC/private networking where applicable
- [ ] WAF rules configured (Cloudflare)

### Monitoring & Compliance:
- [ ] Security event logging
- [ ] Failed login monitoring
- [ ] Audit trail for sensitive actions
- [ ] GDPR compliance (data deletion)
- [ ] Privacy policy updated
- [ ] Terms of service updated

### Third-party Security:
- [ ] Stripe PCI compliance
- [ ] LiveKit secure room creation
- [ ] GetStream.io token validation
- [ ] OAuth redirect URI validation
- [ ] Webhook signature verification

### Specific Vulnerabilities to Check:
- [ ] Mass assignment protection
- [ ] Open redirects prevented
- [ ] Directory traversal blocked
- [ ] Command injection impossible
- [ ] XXE attacks prevented
- [ ] Insecure deserialization fixed

### Security Testing:
- [ ] Run Brakeman security scanner
- [ ] Run bundler-audit for gem vulnerabilities  
- [ ] Penetration testing performed
- [ ] Security review of JavaScript dependencies
- [ ] Mobile app security audit

### Code Patterns to Implement:
```ruby
# Strong parameters everywhere
def space_params
  params.require(:space).permit(:name, :description)
end

# Secure file uploads
class StreamUploader < ApplicationUploader
  def extension_allowlist
    %w[jpg jpeg png gif mp4 webm]
  end
  
  def size_range
    1..100.megabytes
  end
end

# Rate limiting
class ApplicationController
  rate_limit to: 100, within: 1.minute
end

# Secure API tokens
class ApiToken
  has_secure_token :authentication_token
  
  def rotate\!
    regenerate_authentication_token
  end
end
```

### Emergency Response Plan:
- [ ] Security incident response procedure
- [ ] Data breach notification process
- [ ] Vulnerability disclosure policy
- [ ] Security contact information
- [ ] Backup restoration tested

### Branch: issue-21

## 📋 Implementation Checklist:
- [ ] Review issue requirements above
- [ ] Check NAMESPACING_CONVENTIONS.md before creating models
- [ ] Run validation: `ruby .claude/validate-namespacing.rb "command"`
- [ ] Use super_scaffold for all new models
- [ ] Follow PUBLIC_ROUTES_ARCHITECTURE.md for routes
- [ ] Maintain team context where needed
- [ ] Write tests (Magic Test for UI, RSpec for models)
- [ ] Update documentation if needed

## 🔧 Common Commands:
```bash
# Validate namespacing
ruby .claude/validate-namespacing.rb "rails generate super_scaffold ModelName"

# Generate model
rails generate super_scaffold ModelName ParentModel field:type

# Run tests
rails test
rails test:system

# Check changes
git status
git diff

# When complete
bin/gh-complete 21 "PR title describing changes"
```

## 📚 Key Documentation:
- CLAUDE.md - Project instructions (MUST READ)
- NAMESPACING_CONVENTIONS.md - Model naming rules
- TEAM_SPACE_ARCHITECTURE.md - Team/Space relationship
- PUBLIC_ROUTES_ARCHITECTURE.md - Route structure
- AUTHENTICATION_PASSWORDLESS.md - Auth implementation

## 🚨 Important Notes:
- Public routes do NOT need team context
- Primary subjects (Space, Experience, AccessPass, Stream) should NOT be namespaced
- Supporting models should be namespaced (Creators::Profile, Billing::Purchase)
- Always validate namespacing before generating models

---
*Context generated at: Tue Sep 16 15:26:43 EDT 2025*
