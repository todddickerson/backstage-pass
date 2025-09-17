# Developer Guide

This guide covers the technical architecture, conventions, and development practices for the Backstage Pass platform.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Development Setup](#development-setup)
- [Bullet Train Conventions](#bullet-train-conventions)
- [Model Architecture](#model-architecture)
- [API Development](#api-development)
- [Real-time Features](#real-time-features)
- [Testing Strategy](#testing-strategy)
- [Performance Optimization](#performance-optimization)
- [Security Considerations](#security-considerations)

## Architecture Overview

### Technology Stack

```yaml
Backend:
  Framework: Rails 8.0.2
  Ruby: 3.3.0
  Database: PostgreSQL
  Cache: Redis
  Background: Sidekiq
  
Frontend:
  Framework: Hotwire (Turbo + Stimulus)
  CSS: Tailwind CSS
  JavaScript: ES6 Modules
  Mobile: Turbo Native

External Services:
  Streaming: LiveKit
  Chat: GetStream.io
  Payments: Stripe
  Email: Postmark
  Storage: ActiveStorage (S3)
```

### Application Architecture

```
┌─────────────────────────────────────────────────┐
│                   Web Browser                    │
│                  Mobile Apps                     │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│             Rails Application                    │
│  ┌──────────────────────────────────────────┐   │
│  │          Controllers Layer               │   │
│  │  - Account (Team-scoped)                │   │
│  │  - API (Versioned)                      │   │
│  │  - Public                               │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │           Business Logic                 │   │
│  │  - Models (ActiveRecord)                │   │
│  │  - Services (Business Operations)       │   │
│  │  - Jobs (Background Processing)         │   │
│  └──────────────────────────────────────────┘   │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│          Infrastructure Services                 │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │
│  │Postgres│ │ Redis  │ │Sidekiq │ │  S3    │  │
│  └────────┘ └────────┘ └────────┘ └────────┘  │
└─────────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│           External Services                      │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐  │
│  │LiveKit │ │GetStream│ │ Stripe │ │Postmark│  │
│  └────────┘ └────────┘ └────────┘ └────────┘  │
└─────────────────────────────────────────────────┘
```

## Development Setup

### Prerequisites

```bash
# macOS
brew install postgresql@14 redis rbenv node yarn

# Ubuntu/Debian
sudo apt-get install postgresql redis-server nodejs yarn

# Setup Ruby
rbenv install 3.3.0
rbenv global 3.3.0
```

### Environment Configuration

```bash
# .env.local (for development overrides)
DATABASE_URL=postgresql://localhost/backstage_pass_development
REDIS_URL=redis://localhost:6379/0
SIDEKIQ_REDIS_URL=redis://localhost:6379/1

# External Services (get test keys)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
GETSTREAM_API_KEY=...
GETSTREAM_API_SECRET=...
```

### Running Locally

```bash
# Start all services
bin/dev

# Or individually
rails server
bin/webpack-dev-server
sidekiq
redis-server
```

### Database Management

```bash
# Create and migrate
rails db:create db:migrate

# Seed with sample data
rails db:seed

# Reset everything
rails db:reset

# Console access
rails console
```

## Bullet Train Conventions

### Directory Structure

```
app/
├── controllers/
│   ├── account/        # Team-scoped controllers
│   ├── api/v1/        # API endpoints
│   └── public/        # Public pages
├── models/
│   ├── concerns/      # Shared model logic
│   └── validators/    # Custom validators
├── services/          # Business logic services
├── jobs/             # Background jobs
└── views/
    ├── account/      # Team-scoped views
    └── shared/       # Shared partials
```

### Super Scaffolding

Generate CRUD resources quickly:

```bash
# Generate a new model with full CRUD
rails generate super_scaffold Event Team name:text_field description:trix_editor starts_at:date_and_time

# Add to existing model
rails generate super_scaffold:field Event ticket_price:decimal

# Add associations
rails generate super_scaffold:join_model EventAttendee event_id{class_name=Event} user_id{class_name=User}
```

### Authorization Pattern

All team-scoped controllers use Bullet Train's authorization:

```ruby
class Account::ExperiencesController < Account::ApplicationController
  # Automatically loads and authorizes through team context
  account_load_and_authorize_resource :experience, through: :space, through_association: :experiences
  
  private
  
  def experience_params
    params.require(:experience).permit(:name, :description, :experience_type, :price_cents)
  end
end
```

## Model Architecture

### Core Domain Models

```ruby
# User (Devise + Bullet Train extensions)
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable
  
  has_many :memberships, dependent: :destroy
  has_many :teams, through: :memberships
  has_many :access_grants
  
  # Current team context
  belongs_to :current_team, class_name: "Team", optional: true
end

# Team (Multi-tenant boundary)
class Team < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :spaces, dependent: :destroy
  has_one :primary_space, -> { where(is_primary: true) }, class_name: "Space"
  
  after_create :create_primary_space
end

# Space (Content container)
class Space < ApplicationRecord
  belongs_to :team
  has_many :experiences, dependent: :destroy
  has_many :access_passes, dependent: :destroy
  
  validates :slug, presence: true, uniqueness: { scope: :team_id }
end

# Experience (Content type)
class Experience < ApplicationRecord
  belongs_to :space
  has_many :streams, dependent: :destroy
  
  enum experience_type: {
    live_stream: "live_stream",
    course: "course",
    community: "community",
    consultation: "consultation",
    digital_product: "digital_product"
  }
  
  monetized_with :price
end

# Stream (Live session)
class Stream < ApplicationRecord
  belongs_to :experience
  has_one :chat_room, dependent: :destroy
  
  state_machine :status, initial: :scheduled do
    event :start do
      transition scheduled: :live
    end
    
    event :end do
      transition live: :ended
    end
  end
  
  before_start :create_livekit_room
  after_end :archive_recording
end
```

### Service Objects

```ruby
# app/services/livekit_service.rb
class LivekitService
  def self.create_room(stream)
    client.create_room(
      name: stream.room_name,
      empty_timeout: 300,
      max_participants: stream.max_participants
    )
  end
  
  def self.generate_token(stream, user, can_publish: false)
    token = AccessToken.new(
      api_key: ENV['LIVEKIT_API_KEY'],
      api_secret: ENV['LIVEKIT_API_SECRET']
    )
    
    token.identity = user.id.to_s
    token.name = user.name
    token.add_grant(
      video_grant: VideoGrant.new(
        room_join: true,
        room: stream.room_name,
        can_publish: can_publish,
        can_subscribe: true
      )
    )
    
    token.to_jwt
  end
end
```

## API Development

### Versioning Strategy

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :spaces, only: [:index, :show]
    resources :experiences, only: [:index, :show]
    resources :streams, only: [:index, :show] do
      member do
        post :join
      end
    end
  end
end
```

### API Controllers

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  include Api::V1::Authentication
  include Api::V1::Authorization
  
  before_action :authenticate_user!
  
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from CanCan::AccessDenied, with: :forbidden
  
  private
  
  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end
  
  def forbidden
    render json: { error: "Access denied" }, status: :forbidden
  end
end
```

### API Serialization

```ruby
# app/serializers/api/v1/experience_serializer.rb
class Api::V1::ExperienceSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :experience_type, :price_cents
  
  belongs_to :space
  has_many :streams
  
  def price_cents
    object.price_cents if current_user.can?(:read_price, object)
  end
end
```

## Real-time Features

### Turbo Streams

```erb
<!-- app/views/streams/show.html.erb -->
<%= turbo_stream_from @stream %>

<div id="<%= dom_id(@stream, :viewers) %>">
  <%= @stream.viewer_count %> viewers
</div>

<div id="<%= dom_id(@stream, :chat) %>">
  <%= render @stream.messages %>
</div>
```

```ruby
# app/models/stream.rb
class Stream < ApplicationRecord
  after_update_commit :broadcast_viewer_count
  
  private
  
  def broadcast_viewer_count
    broadcast_update_to self,
      target: "#{dom_id(self)}_viewers",
      partial: "streams/viewer_count",
      locals: { stream: self }
  end
end
```

### WebSocket Connections

```javascript
// app/javascript/channels/stream_channel.js
import consumer from "./consumer"

consumer.subscriptions.create(
  { 
    channel: "StreamChannel",
    stream_id: document.querySelector("[data-stream-id]").dataset.streamId
  },
  {
    connected() {
      console.log("Connected to stream")
    },
    
    received(data) {
      // Handle incoming data
      if (data.type === "viewer_update") {
        this.updateViewerCount(data.count)
      }
    },
    
    updateViewerCount(count) {
      document.getElementById("viewer-count").textContent = count
    }
  }
)
```

## Testing Strategy

### Test Organization

```
test/
├── models/           # Unit tests
├── controllers/      # Controller tests
├── integration/      # Integration tests
├── system/          # Browser tests
├── services/        # Service object tests
├── jobs/            # Background job tests
└── support/         # Test helpers
    └── external_service_mocks.rb
```

### Testing Patterns

```ruby
# test/models/experience_test.rb
class ExperienceTest < ActiveSupport::TestCase
  test "validates presence of required fields" do
    experience = Experience.new
    assert_not experience.valid?
    assert_includes experience.errors[:name], "can't be blank"
    assert_includes experience.errors[:experience_type], "can't be blank"
  end
  
  test "live_stream type requires real-time features" do
    experience = create(:experience, experience_type: "live_stream")
    assert experience.requires_real_time?
    assert experience.live_streaming?
  end
end

# test/integration/streaming_integration_test.rb
class StreamingIntegrationTest < ActionDispatch::IntegrationTest
  test "complete streaming workflow" do
    ExternalServiceMocks::LiveKit.mock_all! do
      stream = create(:stream, status: "scheduled")
      
      # Start stream
      stream.start!
      assert_equal "live", stream.status
      
      # Viewers can join
      token = LivekitService.generate_token(stream, @viewer, can_publish: false)
      assert_not_nil token
      
      # End stream
      stream.end!
      assert_equal "ended", stream.status
    end
  end
end
```

### Mocking External Services

```ruby
# test/support/external_service_mocks.rb
module ExternalServiceMocks
  module LiveKit
    def self.mock_room_service!
      room_service = Minitest::Mock.new
      room_service.expect(:create_room, OpenStruct.new(sid: "RM_TEST123"))
      LivekitService.stub(:room_service, room_service) { yield }
    end
  end
  
  module Stripe
    def self.mock_checkout!
      session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/test")
      Stripe::Checkout::Session.stub(:create, session) { yield }
    end
  end
end
```

## Performance Optimization

### Database Optimization

```ruby
# Add indexes for common queries
class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :experiences, [:space_id, :experience_type]
    add_index :streams, [:experience_id, :status]
    add_index :access_grants, [:user_id, :expires_at]
    add_index :spaces, :slug
  end
end

# Use includes to prevent N+1
Space.includes(:experiences, :access_passes).where(team: current_team)

# Add counter caches
class AddCounterCaches < ActiveRecord::Migration[7.0]
  def change
    add_column :spaces, :experiences_count, :integer, default: 0
    add_column :experiences, :streams_count, :integer, default: 0
    
    Space.reset_counters(Space.pluck(:id), :experiences)
    Experience.reset_counters(Experience.pluck(:id), :streams)
  end
end
```

### Caching Strategy

```ruby
# Fragment caching in views
<% cache [@space, @space.updated_at] do %>
  <%= render @space %>
<% end %>

# Russian doll caching
<% cache @space do %>
  <h1><%= @space.name %></h1>
  <% @space.experiences.each do |experience| %>
    <% cache experience do %>
      <%= render experience %>
    <% end %>
  <% end %>
<% end %>

# Low-level caching
class ExperienceService
  def popular_experiences
    Rails.cache.fetch("popular_experiences", expires_in: 1.hour) do
      Experience.joins(:access_grants)
                .group(:id)
                .order("COUNT(access_grants.id) DESC")
                .limit(10)
    end
  end
end
```

### Background Jobs

```ruby
# app/jobs/stream_archive_job.rb
class StreamArchiveJob < ApplicationJob
  queue_as :default
  
  def perform(stream_id)
    stream = Stream.find(stream_id)
    
    # Download recording from LiveKit
    recording = LivekitService.download_recording(stream)
    
    # Upload to S3
    stream.recording.attach(
      io: StringIO.new(recording),
      filename: "stream_#{stream.id}.mp4",
      content_type: "video/mp4"
    )
    
    # Notify creator
    StreamMailer.recording_ready(stream).deliver_later
  end
end
```

## Security Considerations

### Authentication & Authorization

```ruby
# Strong parameters
def experience_params
  params.require(:experience)
        .permit(:name, :description, :experience_type, :price_cents)
        .merge(space: current_space)
end

# Team-scoped queries
def current_space
  @current_space ||= current_team.spaces.find(params[:space_id])
end

# Ability checks
class Ability
  include CanCan::Ability
  
  def initialize(user)
    return unless user.present?
    
    # Team member permissions
    can :read, Space, team: { id: user.team_ids }
    can :manage, Space, team: { memberships: { user_id: user.id, admin: true } }
    
    # Access grant permissions
    can :read, Experience do |experience|
      experience.access_grants.active.exists?(user: user)
    end
  end
end
```

### Input Validation

```ruby
class Experience < ApplicationRecord
  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 5000 }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, less_than: 1000000 }
  validates :experience_type, inclusion: { in: experience_types.keys }
  
  # Sanitize HTML content
  before_save :sanitize_description
  
  private
  
  def sanitize_description
    self.description = ActionView::Base.full_sanitizer.sanitize(description)
  end
end
```

### API Security

```ruby
# Rate limiting
class Api::V1::BaseController < ActionController::API
  before_action :check_rate_limit
  
  private
  
  def check_rate_limit
    key = "api_rate_limit:#{current_user.id}"
    count = Rails.cache.increment(key, 1, expires_in: 1.minute)
    
    if count > 60
      render json: { error: "Rate limit exceeded" }, status: :too_many_requests
    end
  end
end

# CORS configuration
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV['ALLOWED_ORIGINS']&.split(',') || []
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: true
  end
end
```

## Development Tools

### Debugging

```ruby
# Add to Gemfile development group
gem 'pry-rails'
gem 'better_errors'
gem 'binding_of_caller'
gem 'bullet' # N+1 detection
gem 'rack-mini-profiler'

# Debug in console
binding.pry # Breakpoint
ap object # Awesome print
reload! # Reload console

# SQL logging
ActiveRecord::Base.logger = Logger.new(STDOUT)
```

### Code Quality

```bash
# Run linter
standardrb --fix

# Security audit
bundle audit
brakeman

# Test coverage
COVERAGE=true rails test
open coverage/index.html
```

## Deployment Checklist

- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] Assets precompiled
- [ ] SSL certificates valid
- [ ] Background jobs running
- [ ] Error monitoring active
- [ ] Backups configured
- [ ] Logging enabled
- [ ] Performance monitoring
- [ ] Security headers set

## Resources

- [Bullet Train Documentation](https://bullettrain.co/docs)
- [Rails Guides](https://guides.rubyonrails.org)
- [Hotwire Documentation](https://hotwired.dev)
- [LiveKit Documentation](https://docs.livekit.io)
- [Stripe API Reference](https://stripe.com/docs/api)
- [GetStream Chat Docs](https://getstream.io/chat/docs)

---

For questions and support, reach out to the development team or open an issue on GitHub.