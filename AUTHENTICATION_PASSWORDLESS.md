# Passwordless Authentication Implementation

## ✅ Yes, We Can Do Passwordless with 6-Digit Codes

Despite using Bullet Train (which uses Devise), we can implement passwordless authentication with 6-digit codes by creating a custom system that works WITH Bullet Train's patterns.

## Architecture Overview

### 1. Custom 6-Digit OTP System
**NOT using devise-passwordless** (that uses magic links, not codes)

```ruby
# Generate model with super_scaffold
rails generate super_scaffold AuthCode User \
  code:text_field \
  purpose:options{login,signup,purchase} \
  phone:text_field \
  email:text_field \
  expires_at:date_and_time_field \
  consumed_at:date_and_time_field

# app/models/auth_code.rb
class AuthCode < ApplicationRecord
  belongs_to :user, optional: true  # Optional for signup
  
  before_create :generate_code
  
  scope :active, -> { where(consumed_at: nil).where('expires_at > ?', Time.current) }
  scope :for_email, ->(email) { where(email: email.downcase) }
  scope :for_phone, ->(phone) { where(phone: phone) }
  
  def consume!
    update!(consumed_at: Time.current)
  end
  
  def expired?
    expires_at < Time.current || consumed_at.present?
  end
  
  private
  
  def generate_code
    self.code = SecureRandom.random_number(900000) + 100000  # 6 digits
    self.expires_at = 10.minutes.from_now
  end
end
```

### 2. Authentication Flow

```ruby
# app/controllers/public/auth/sessions_controller.rb
class Public::Auth::SessionsController < Public::ApplicationController
  def new
    # Show email/phone input form
  end
  
  def send_code
    identifier = params[:identifier]  # email or phone
    
    # Check if user exists
    user = User.find_by(email: identifier) || User.find_by(phone: identifier)
    
    # Create auth code (works for existing or new users)
    auth_code = AuthCode.create!(
      email: identifier.include?('@') ? identifier : nil,
      phone: identifier.include?('@') ? nil : identifier,
      user: user,
      purpose: user ? 'login' : 'signup'
    )
    
    # Send code via email or SMS
    if auth_code.email?
      AuthMailer.send_code(auth_code).deliver_later
    else
      SmsService.send_code(auth_code.phone, auth_code.code)
    end
    
    session[:auth_code_id] = auth_code.id
    redirect_to verify_auth_path
  end
  
  def verify
    # Show 6-digit code input form
  end
  
  def authenticate
    auth_code = AuthCode.active.find(session[:auth_code_id])
    
    if auth_code.code == params[:code]
      auth_code.consume!
      
      if auth_code.user
        # Existing user - sign in
        sign_in(auth_code.user)
        redirect_to account_dashboard_path
      else
        # New user - create account
        user = User.create!(
          email: auth_code.email,
          phone: auth_code.phone,
          # Create default team (Bullet Train requirement)
          teams: [Team.create!(name: auth_code.email || auth_code.phone)]
        )
        sign_in(user)
        redirect_to onboarding_path
      end
    else
      flash[:alert] = "Invalid code"
      redirect_to verify_auth_path
    end
  end
end
```

### 3. Purchase Flow Integration

```ruby
# app/controllers/public/purchases_controller.rb
class Public::PurchasesController < Public::ApplicationController
  def new
    @access_pass = AccessPass.find(params[:access_pass_id])
    
    if current_user
      # Already authenticated - go to checkout
      redirect_to checkout_path(@access_pass)
    else
      # Need authentication first
      session[:pending_purchase_id] = @access_pass.id
      redirect_to new_auth_session_path
    end
  end
  
  def checkout
    @access_pass = AccessPass.find(params[:id])
    
    # After auth, continue with Stripe
    if session[:pending_purchase_id]
      # User just authenticated for this purchase
      session.delete(:pending_purchase_id)
    end
    
    # Proceed with Stripe Checkout or Elements
  end
end
```

## Key Implementation Points

### 1. Works WITH Bullet Train
- Uses `super_scaffold` for AuthCode model
- Maintains Team context where needed
- Preserves magic comments (🚅)
- Uses Bullet Train's form components

### 2. Flexible Authentication
- Works for both login and signup
- Single flow for new and existing users
- Can use email OR phone number
- Seamless purchase experience

### 3. Security Considerations
```ruby
# Rate limiting
class AuthCode < ApplicationRecord
  validate :rate_limit_check
  
  private
  
  def rate_limit_check
    recent_codes = AuthCode.where(email: email)
                          .where('created_at > ?', 1.hour.ago)
                          .count
    
    if recent_codes >= 5
      errors.add(:base, "Too many attempts. Please try again later.")
    end
  end
end
```

## Routes Configuration

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Public authentication (passwordless)
  namespace :public do
    namespace :auth do
      resources :sessions, only: [] do
        collection do
          get :new
          post :send_code
          get :verify
          post :authenticate
        end
      end
    end
  end
  
  # Regular Devise routes still work for admin/team members
  devise_for :users, controllers: {
    registrations: "registrations",
    sessions: "sessions",  # Standard password login for team members
  }
  
  # Public routes (NO team context needed)
  scope module: 'public' do
    get '@:username', to: 'creator_profiles#show'
    get ':space_slug', to: 'spaces#show'
    get ':space_slug/:pass_slug', to: 'access_passes#show'
    
    resources :purchases, only: [:new, :create] do
      member do
        get :checkout
      end
    end
  end
  
  # Account routes (team context)
  namespace :account do
    # ... standard Bullet Train team-scoped routes
  end
end
```

## Testing with Magic Test

```ruby
# test/system/passwordless_auth_test.rb
require "application_system_test_case"

class PasswordlessAuthTest < ApplicationSystemTestCase
  include MagicTest::Support
  
  test "new user purchases with passwordless auth" do
    space = create(:space, :published)
    access_pass = create(:access_pass, space: space, price: 1000)
    
    visit public_space_path(space)
    click_button "Get Access"
    
    # Passwordless flow
    fill_in "Email or Phone", with: "new@example.com"
    click_button "Send Code"
    
    # Get code from test helper
    auth_code = AuthCode.last
    
    fill_in "code", with: auth_code.code
    click_button "Verify"
    
    # Now in checkout
    assert_text "Complete Purchase"
    
    # Stripe checkout...
  end
end
```

## Migration from Standard Auth

For existing users with passwords:
1. Keep password login as option
2. Add "Login with code" button
3. Gradually migrate users
4. Eventually remove password login

## SMS Service Setup

```ruby
# app/services/sms_service.rb
class SmsService
  def self.send_code(phone, code)
    if Rails.env.production?
      # Twilio integration
      client = Twilio::REST::Client.new
      client.messages.create(
        from: Rails.application.credentials.twilio_phone,
        to: phone,
        body: "Your Backstage Pass code: #{code}"
      )
    else
      # Development: log to console
      Rails.logger.info "SMS to #{phone}: Your code is #{code}"
    end
  end
end
```

## Benefits of This Approach

1. **User Experience**: No passwords to remember
2. **Security**: Codes expire in 10 minutes
3. **Conversion**: Reduces friction for purchases
4. **Flexibility**: Works with email or phone
5. **Bullet Train Compatible**: Uses framework patterns

This implementation gives us true passwordless authentication with 6-digit codes while working WITH Bullet Train's architecture, not against it.