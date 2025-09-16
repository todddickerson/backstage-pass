# Purchase Flow Plan - AccessPass Payment Implementation

## Overview

This document outlines the complete purchase flow for Backstage Pass, supporting all pricing models (free, one-time, monthly, yearly) as defined in our AccessPass product architecture.

## Pricing Types Support

### Current Implementation (AccessPass Model)

```ruby
# app/models/access_pass.rb
enum :pricing_type, {
  free: 'free',
  one_time: 'one_time', 
  monthly: 'monthly',
  yearly: 'yearly'
}
```

✅ **All pricing types are implemented in the AccessPass model**

## Purchase Flow Architecture

### 1. Free Access Passes

**Flow:**
1. User clicks "Get Access" on free AccessPass
2. System checks if user is authenticated
   - If yes → Create AccessGrant immediately
   - If no → Redirect to passwordless auth (Phase 2) or standard auth (Phase 1)
3. Create AccessGrant with no payment required
4. Redirect to purchased content

**Implementation:**
```ruby
# app/controllers/public/purchases_controller.rb
class Public::PurchasesController < Public::ApplicationController
  def create
    @access_pass = AccessPass.find(params[:access_pass_id])
    
    if @access_pass.free?
      # No payment needed - create grant immediately
      @access_grant = current_user.access_grants.create!(
        team: @access_pass.space.team,
        purchasable: @access_pass.space,
        access_pass: @access_pass,
        status: 'active',
        expires_at: nil  # Free passes don't expire
      )
      
      redirect_to space_path(@access_pass.space), 
                  notice: "You now have access!"
    else
      # Continue to payment flow...
    end
  end
end
```

### 2. One-Time Purchases

**Flow:**
1. User clicks "Get Access" on paid AccessPass
2. Authenticate if needed (store pending_purchase_id in session)
3. Show custom checkout UI with Stripe Elements
4. Process one-time charge through Stripe
5. Create Billing::Purchase record
6. Create AccessGrant with appropriate expiration
7. Redirect to purchased content

**Implementation:**
```ruby
# app/controllers/billing/checkouts_controller.rb
class Billing::CheckoutsController < ApplicationController
  def create
    @access_pass = AccessPass.find(params[:access_pass_id])
    
    # Create Stripe charge for one-time payment
    charge = Stripe::Charge.create(
      amount: @access_pass.price_cents,
      currency: 'usd',
      customer: current_user.stripe_customer_id,
      metadata: {
        access_pass_id: @access_pass.id,
        user_id: current_user.id
      }
    )
    
    # Record the purchase
    purchase = Billing::Purchase.create!(
      access_pass: @access_pass,
      user: current_user,
      team: @access_pass.space.team,
      amount_cents: @access_pass.price_cents,
      stripe_charge_id: charge.id,
      payment_type: 'one_time'
    )
    
    # Grant access
    access_grant = AccessGrant.create!(
      user: current_user,
      team: @access_pass.space.team,
      purchasable: @access_pass.space,
      access_pass: @access_pass,
      status: 'active',
      expires_at: nil  # One-time purchases don't expire
    )
    
    redirect_to space_path(@access_pass.space)
  end
end
```

### 3. Recurring Subscriptions (Monthly/Yearly)

**Flow:**
1. User clicks "Get Access" on subscription AccessPass
2. Authenticate if needed
3. Show subscription terms clearly
4. Create Stripe subscription (not just charge)
5. Create Billing::Purchase with subscription_id
6. Create AccessGrant with renewal logic
7. Set up webhook for renewal/cancellation

**Implementation:**
```ruby
# app/controllers/billing/subscriptions_controller.rb
class Billing::SubscriptionsController < ApplicationController
  def create
    @access_pass = AccessPass.find(params[:access_pass_id])
    
    # Determine Stripe price/plan ID based on pricing type
    stripe_price_id = case @access_pass.pricing_type
    when 'monthly'
      @access_pass.stripe_monthly_price_id
    when 'yearly'
      @access_pass.stripe_yearly_price_id
    end
    
    # Create Stripe subscription
    subscription = Stripe::Subscription.create(
      customer: current_user.stripe_customer_id,
      items: [{price: stripe_price_id}],
      metadata: {
        access_pass_id: @access_pass.id,
        user_id: current_user.id
      }
    )
    
    # Record the purchase
    purchase = Billing::Purchase.create!(
      access_pass: @access_pass,
      user: current_user,
      team: @access_pass.space.team,
      amount_cents: @access_pass.price_cents,
      stripe_subscription_id: subscription.id,
      payment_type: @access_pass.pricing_type,
      next_billing_date: Time.at(subscription.current_period_end)
    )
    
    # Grant access with expiration
    access_grant = AccessGrant.create!(
      user: current_user,
      team: @access_pass.space.team,
      purchasable: @access_pass.space,
      access_pass: @access_pass,
      status: 'active',
      expires_at: Time.at(subscription.current_period_end)
    )
    
    redirect_to space_path(@access_pass.space)
  end
end
```

## Models Required

### 1. Billing::Purchase Model (NAMESPACED)

```bash
# Super scaffold command
ruby .claude/validate-namespacing.rb "rails generate super_scaffold Billing::Purchase ..."

rails generate super_scaffold Billing::Purchase AccessPass,User \
  amount_cents:number_field \
  stripe_charge_id:text_field \
  stripe_subscription_id:text_field \
  payment_type:options{one_time,monthly,yearly,free} \
  status:options{pending,completed,failed,refunded} \
  next_billing_date:date_field
```

### 2. AccessGrant Enhancements

```ruby
class AccessGrant < ApplicationRecord
  belongs_to :team
  belongs_to :user
  belongs_to :purchasable, polymorphic: true
  belongs_to :access_pass, optional: true
  
  enum :status, {
    active: 'active',
    expired: 'expired',
    cancelled: 'cancelled',
    refunded: 'refunded'
  }
  
  scope :active, -> { where(status: 'active').where('expires_at IS NULL OR expires_at > ?', Time.current) }
  
  def renewable?
    access_pass&.recurring? && expires_at.present?
  end
  
  def days_until_expiration
    return nil unless expires_at
    ((expires_at - Time.current) / 1.day).round
  end
end
```

## Stripe Integration

### Required Stripe Objects

1. **Products**: One per AccessPass
2. **Prices**: 
   - One-time price for one_time AccessPasses
   - Recurring prices for monthly/yearly AccessPasses
3. **Customers**: One per User
4. **Subscriptions**: For recurring AccessPasses
5. **Charges**: For one-time AccessPasses

### Webhook Handlers

```ruby
# app/controllers/webhooks/stripe_controller.rb
class Webhooks::StripeController < ApplicationController
  def create
    case event.type
    when 'customer.subscription.updated'
      handle_subscription_update(event)
    when 'customer.subscription.deleted'
      handle_subscription_cancellation(event)
    when 'invoice.payment_succeeded'
      handle_renewal(event)
    when 'charge.refunded'
      handle_refund(event)
    end
  end
  
  private
  
  def handle_renewal(event)
    subscription_id = event.data.object.subscription
    purchase = Billing::Purchase.find_by(stripe_subscription_id: subscription_id)
    
    if purchase
      # Extend access grant
      grant = purchase.user.access_grants.find_by(access_pass: purchase.access_pass)
      grant.update!(
        expires_at: Time.at(event.data.object.period_end),
        status: 'active'
      )
    end
  end
end
```

## UI Components

### 1. Pricing Display

```erb
<!-- app/views/public/access_passes/_pricing.html.erb -->
<div class="pricing-display">
  <% if @access_pass.free? %>
    <span class="price">Free</span>
  <% elsif @access_pass.pricing_type == 'one_time' %>
    <span class="price"><%= number_to_currency(@access_pass.price_cents / 100.0) %></span>
    <span class="period">one-time payment</span>
  <% elsif @access_pass.pricing_type == 'monthly' %>
    <span class="price"><%= number_to_currency(@access_pass.price_cents / 100.0) %></span>
    <span class="period">per month</span>
  <% elsif @access_pass.pricing_type == 'yearly' %>
    <span class="price"><%= number_to_currency(@access_pass.price_cents / 100.0) %></span>
    <span class="period">per year</span>
  <% end %>
</div>
```

### 2. Stripe Elements Integration

```javascript
// app/javascript/controllers/checkout_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    publicKey: String,
    clientSecret: String,
    returnUrl: String
  }
  
  async connect() {
    this.stripe = Stripe(this.publicKeyValue)
    this.elements = this.stripe.elements()
    
    // Create card element
    this.cardElement = this.elements.create('card', {
      style: {
        base: {
          fontSize: '16px',
          color: '#32325d'
        }
      }
    })
    
    this.cardElement.mount('#card-element')
  }
  
  async submit(event) {
    event.preventDefault()
    
    const {error} = await this.stripe.confirmCardPayment(
      this.clientSecretValue,
      {
        payment_method: {
          card: this.cardElement
        },
        return_url: this.returnUrlValue
      }
    )
    
    if (!error) {
      // Payment succeeded, submit form
      this.element.submit()
    }
  }
}
```

## Testing Strategy

### 1. Free AccessPass Test
```ruby
test "user can claim free access pass" do
  access_pass = create(:access_pass, pricing_type: 'free', price_cents: 0)
  
  sign_in @user
  post billing_purchases_path, params: { access_pass_id: access_pass.id }
  
  assert_redirected_to space_path(access_pass.space)
  assert @user.access_grants.exists?(access_pass: access_pass)
end
```

### 2. One-Time Purchase Test
```ruby
test "user can purchase one-time access pass" do
  access_pass = create(:access_pass, pricing_type: 'one_time', price_cents: 1000)
  
  VCR.use_cassette("stripe_charge") do
    post billing_checkouts_path, params: {
      access_pass_id: access_pass.id,
      stripe_token: 'tok_visa'
    }
  end
  
  assert @user.access_grants.active.exists?(access_pass: access_pass)
end
```

### 3. Subscription Test
```ruby
test "user can subscribe to monthly access pass" do
  access_pass = create(:access_pass, pricing_type: 'monthly', price_cents: 999)
  
  VCR.use_cassette("stripe_subscription") do
    post billing_subscriptions_path, params: {
      access_pass_id: access_pass.id,
      stripe_token: 'tok_visa'
    }
  end
  
  grant = @user.access_grants.find_by(access_pass: access_pass)
  assert grant.expires_at > 29.days.from_now
end
```

## Phase 1 vs Phase 2

### Phase 1 (Current - Week 2)
- ✅ All pricing types in AccessPass model
- ✅ Basic Stripe Elements integration
- ✅ One-time payments
- ⏳ Basic subscription setup
- ❌ Passwordless auth (use standard Devise)

### Phase 2 (Future)
- Full subscription management UI
- Cancellation flows
- Upgrade/downgrade between tiers
- Passwordless 6-digit OTP auth
- Split payments
- Stripe Connect for creator payouts

## Next Steps (Issue #5 Implementation)

1. Create `Billing::Purchase` model with super_scaffold
2. Implement Stripe Elements checkout UI
3. Add purchase controller for each payment type
4. Set up Stripe webhooks for subscriptions
5. Test all pricing scenarios

## Summary

✅ **YES** - Our plan covers all pricing types:
- **Free**: Direct AccessGrant creation, no payment
- **One-Time**: Stripe Charge + permanent AccessGrant
- **Monthly**: Stripe Subscription + renewable AccessGrant
- **Yearly**: Stripe Subscription + renewable AccessGrant

The AccessPass model already has the `pricing_type` enum properly configured. We just need to implement the corresponding purchase flows for each type when we tackle Issue #5 in Week 2.