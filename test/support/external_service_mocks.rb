# External Service Mocks for Testing
# This module provides mocks for all external services to ensure
# tests can run without actual API calls and to provide predictable responses

module ExternalServiceMocks
  # LiveKit Mock Service
  module LiveKit
    def self.mock_room_service!
      room_service = Minitest::Mock.new
      
      # Mock room creation
      room_service.expect(:create_room, 
        OpenStruct.new(name: "test_room", sid: "RM_TEST123"),
        [String]
      )
      
      # Mock room deletion
      room_service.expect(:delete_room, true, [String])
      
      # Mock list rooms
      room_service.expect(:list_rooms, 
        [OpenStruct.new(name: "test_room", sid: "RM_TEST123")],
        []
      )
      
      # Mock get room
      room_service.expect(:get_room,
        OpenStruct.new(name: "test_room", sid: "RM_TEST123", num_participants: 0),
        [String]
      )
      
      # Replace the actual service with mock
      LivekitService.stub(:room_service, room_service) do
        yield
      end
    end
    
    def self.mock_token_service!
      # Mock token generation
      LivekitService.stub(:generate_token, "mock_token_#{SecureRandom.hex(8)}") do
        yield
      end
    end
    
    def self.mock_all!
      mock_room_service! do
        mock_token_service! do
          yield
        end
      end
    end
  end
  
  # Stripe Mock Service
  module Stripe
    def self.mock_customer_service!
      customer = OpenStruct.new(
        id: "cus_test_#{SecureRandom.hex(8)}",
        email: "test@example.com",
        created: Time.current.to_i
      )
      
      ::Stripe::Customer.stub(:create, customer) do
        ::Stripe::Customer.stub(:retrieve, customer) do
          yield
        end
      end
    end
    
    def self.mock_subscription_service!
      subscription = OpenStruct.new(
        id: "sub_test_#{SecureRandom.hex(8)}",
        status: "active",
        current_period_end: 30.days.from_now.to_i,
        items: OpenStruct.new(data: [
          OpenStruct.new(price: OpenStruct.new(
            id: "price_test",
            unit_amount: 999
          ))
        ])
      )
      
      ::Stripe::Subscription.stub(:create, subscription) do
        ::Stripe::Subscription.stub(:retrieve, subscription) do
          ::Stripe::Subscription.stub(:update, subscription) do
            ::Stripe::Subscription.stub(:cancel, subscription.tap { |s| s.status = "canceled" }) do
              yield
            end
          end
        end
      end
    end
    
    def self.mock_payment_intent_service!
      payment_intent = OpenStruct.new(
        id: "pi_test_#{SecureRandom.hex(8)}",
        status: "succeeded",
        amount: 999,
        currency: "usd",
        client_secret: "pi_test_secret_#{SecureRandom.hex(8)}"
      )
      
      ::Stripe::PaymentIntent.stub(:create, payment_intent) do
        ::Stripe::PaymentIntent.stub(:retrieve, payment_intent) do
          ::Stripe::PaymentIntent.stub(:confirm, payment_intent) do
            yield
          end
        end
      end
    end
    
    def self.mock_checkout_session_service!
      session = OpenStruct.new(
        id: "cs_test_#{SecureRandom.hex(8)}",
        url: "https://checkout.stripe.com/test/session",
        payment_status: "paid",
        customer: "cus_test_123",
        line_items: OpenStruct.new(data: [])
      )
      
      ::Stripe::Checkout::Session.stub(:create, session) do
        ::Stripe::Checkout::Session.stub(:retrieve, session) do
          yield
        end
      end
    end
    
    def self.mock_price_service!
      price = OpenStruct.new(
        id: "price_test_#{SecureRandom.hex(8)}",
        unit_amount: 999,
        currency: "usd",
        product: "prod_test_123"
      )
      
      ::Stripe::Price.stub(:create, price) do
        ::Stripe::Price.stub(:retrieve, price) do
          ::Stripe::Price.stub(:list, OpenStruct.new(data: [price])) do
            yield
          end
        end
      end
    end
    
    def self.mock_all!
      mock_customer_service! do
        mock_subscription_service! do
          mock_payment_intent_service! do
            mock_checkout_session_service! do
              mock_price_service! do
                yield
              end
            end
          end
        end
      end
    end
  end
  
  # GetStream Mock Service
  module GetStream
    def self.mock_chat_client!
      chat_client = Minitest::Mock.new
      
      # Mock channel creation
      channel = OpenStruct.new(
        id: "channel_test_#{SecureRandom.hex(8)}",
        type: "messaging",
        cid: "messaging:test",
        created_by: OpenStruct.new(id: "user_test"),
        members: [],
        messages: []
      )
      
      chat_client.expect(:channel, channel, ["messaging", String])
      chat_client.expect(:create_token, "test_token_#{SecureRandom.hex(8)}", [String])
      
      # Mock user operations
      user = OpenStruct.new(
        id: "user_test_#{SecureRandom.hex(8)}",
        name: "Test User",
        image: "https://example.com/avatar.jpg"
      )
      
      chat_client.expect(:update_user, user, [Hash])
      chat_client.expect(:upsert_user, user, [Hash])
      
      # Replace actual client with mock
      GetstreamService.stub(:chat_client, chat_client) do
        yield
      end
    end
    
    def self.mock_channel_operations!
      channel = OpenStruct.new(
        id: "channel_test",
        type: "messaging",
        cid: "messaging:test",
        created_by: OpenStruct.new(id: "user_test"),
        members: [],
        messages: [],
        created?: true,
        send_message: OpenStruct.new(
          id: "msg_test_#{SecureRandom.hex(8)}",
          text: "Test message",
          user: OpenStruct.new(id: "user_test")
        ),
        add_members: true,
        remove_members: true,
        delete: true,
        update: true
      )
      
      # Stub channel operations
      channel.define_singleton_method(:create) { |_| self }
      channel.define_singleton_method(:watch) { |_| self }
      channel.define_singleton_method(:stop_watching) { |_| self }
      channel.define_singleton_method(:query) { |_| self }
      
      GetstreamService.stub(:create_channel, channel) do
        GetstreamService.stub(:get_channel, channel) do
          yield
        end
      end
    end
    
    def self.mock_all!
      mock_chat_client! do
        mock_channel_operations! do
          yield
        end
      end
    end
  end
  
  # Convenience method to mock all services at once
  def self.mock_all_services!
    LiveKit.mock_all! do
      Stripe.mock_all! do
        GetStream.mock_all! do
          yield
        end
      end
    end
  end
  
  # Helper to verify service availability for conditional mocking
  def self.service_available?(service_name)
    case service_name
    when :livekit
      ENV["LIVEKIT_API_KEY"].present? && ENV["LIVEKIT_API_SECRET"].present?
    when :stripe
      ENV["STRIPE_SECRET_KEY"].present?
    when :getstream
      ENV["GETSTREAM_API_KEY"].present? && ENV["GETSTREAM_API_SECRET"].present?
    else
      false
    end
  end
  
  # Mock only unavailable services (useful for CI/CD)
  def self.mock_unavailable_services!
    if service_available?(:livekit)
      yield
    else
      LiveKit.mock_all! { yield }
    end
  end
end