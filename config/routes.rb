# Define reserved paths that should NOT be treated as space slugs
# This prevents system routes from being caught by the catch-all
unless defined?(RESERVED_PATHS)
  RESERVED_PATHS = %w[
    users admin api account webhooks rails assets packs sidekiq avo
    explore about terms privacy
  ].freeze
end

Rails.application.routes.draw do
  # Health check endpoint for deployment monitoring
  get "health", to: "health#show", as: :health_check

  # See `config/routes/*.rb` to customize these configurations.
  draw "concerns"
  draw "devise"
  draw "sidekiq"
  draw "avo"

  # Hotwire Native configuration endpoint
  get "/hotwire-native-config/:platform", to: "hotwire_native#configuration", as: :hotwire_native_config

  # `collection_actions` is automatically super scaffolded to your routes file when creating certain objects.
  # This is helpful to have around when working with shallow routes and complicated model namespacing. We don't use this
  # by default, but sometimes Super Scaffolding will generate routes that use this for `only` and `except` options.
  collection_actions = [:index, :new, :create] # standard:disable Lint/UselessAssignment

  # This helps mark `resources` definitions below as not actually defining the routes for a given resource, but just
  # making it possible for developers to extend definitions that are already defined by the `bullet_train` Ruby gem.
  # TODO Would love to get this out of the application routes file.
  extending = {only: []}

  # IMPORTANT: Account namespace MUST come before catch-all routes

  namespace :api do
    draw "api/v1"
    # 🚅 super scaffolding will insert new api versions above this line.
  end
  namespace :account do
    get "analytics", to: "analytics#index"
    get "analytics/index"
    shallow do
      # The account root `/` path is routed to `Account::Dashboard#index` by default. You can set it
      # to whatever you want by doing something like this:
      # root to: "some_other_root_controller#index", as: "dashboard"

      # user-level onboarding tasks.
      namespace :onboarding do
        # routes for standard onboarding steps are configured in the `bullet_train` gem, but you can add more here.
      end

      # user specific resources.
      resources :users, extending do
        namespace :oauth do
          # 🚅 super scaffolding will insert new oauth providers above this line.
        end

        # routes for standard user actions and resources are configured in the `bullet_train` gem, but you can add more here.
      end

      # Creator profile management (singular resource)
      resource :creator_profile, only: [:show, :edit, :update, :create]

      # Purchased spaces and streams for viewers
      resources :purchased_spaces, only: [:index, :show]

      # Stream viewing for authenticated users
      resources :streams, only: [:show], controller: "stream_viewing", path: "streams", as: "viewer_streams" do
        member do
          get :video_token
          get :chat_token
          get :stream_info
          post :join_chat
          delete :leave_chat
        end
      end

      # team-level resources.
      resources :teams, extending do
        # routes for many teams actions and resources are configured in the `bullet_train` gem, but you can add more here.

        # add your resources here.

        resources :invitations, extending do
          # routes for standard invitation actions and resources are configured in the `bullet_train` gem, but you can add more here.
        end

        resources :memberships, extending do
          # routes for standard membership actions and resources are configured in the `bullet_train` gem, but you can add more here.
        end

        namespace :integrations do
          # 🚅 super scaffolding will insert new integration installations above this line.
        end

        resources :spaces do
          resources :experiences do
            resources :streams do
              member do
                post :join_chat
                delete :leave_chat
                get :chat_token
                get :video_token
                post :start_stream
                post :stop_stream
                patch :go_live  # Alias for start_stream with better UX
                patch :end_stream  # Alias for stop_stream with better UX
                get :room_info
              end

              namespace :streaming do
                resources :chat_rooms
              end
            end
          end
          resources :access_passes do
            resources :access_pass_experiences
            scope module: "access_passes" do
              resources :waitlist_entries, only: collection_actions
            end
          end

          namespace :access_passes do
            resources :waitlist_entries, except: collection_actions do
              member do
                post :approve
                post :reject
              end
            end
          end
        end

        resources :access_grants
        namespace :billing do
          resources :purchases
        end

        namespace :analytics do
          resources :daily_snapshots
        end
      end
    end
  end

  namespace :webhooks do
    namespace :incoming do
      namespace :oauth do
        # 🚅 super scaffolding will insert new oauth provider webhooks above this line.
      end
    end
  end

  # PUBLIC ROUTES - These come after account/api/webhooks to ensure proper priority
  scope module: "public" do
    # To keep things organized, we put non-authenticated controllers in the `Public::` namespace.
    # The root `/` path is routed to `Public::HomeController#index` by default.
    root to: "home#index"

    # Constraint to check if a path should be treated as a space slug (MOVED UP)
    valid_space_slug = lambda do |request|
      slug = request.path_parameters[:space_slug]
      slug.present? && !RESERVED_PATHS.include?(slug) && !slug.start_with?("_")
    end

    # STREAMING ROUTES - HIGHEST PRIORITY
    # Experience routes WITH valid_space_slug constraint
    constraints(valid_space_slug) do
      get "/:space_slug/:experience_slug", to: "experiences#show",
        constraints: {experience_slug: /[a-zA-Z0-9_-]+/}, as: :public_space_experience
      get "/:space_slug/:experience_slug/streams/:stream_id", to: "experiences#stream", as: :public_experience_stream

      # API endpoints for streaming
      get "/:space_slug/:experience_slug/video_token", to: "experiences#video_token"
      get "/:space_slug/:experience_slug/chat_token", to: "experiences#chat_token"
      get "/:space_slug/:experience_slug/stream_info", to: "experiences#stream_info"

      # Stream-specific API endpoints
      get "/:space_slug/:experience_slug/streams/:stream_id/video_token", to: "experiences#video_token"
      get "/:space_slug/:experience_slug/streams/:stream_id/chat_token", to: "experiences#chat_token"
      get "/:space_slug/:experience_slug/streams/:stream_id/stream_info", to: "experiences#stream_info"
    end

    # Priority routes - these take precedence over catch-all space routes
    # Add static pages here as needed (about, terms, privacy, etc.)
    get "about", to: "pages#about"
    get "terms", to: "pages#terms"
    get "privacy", to: "pages#privacy"

    # Browse all spaces (marketplace index)
    get "explore", to: "spaces#index", as: :explore_spaces

    # Creator profile routes (@username) - must come before catch-all routes
    get "/@:username", to: "creator_profiles#show", constraints: {username: /[a-zA-Z0-9_-]+/}, as: :creator_profile

    # Purchase routes - WITH valid_space_slug constraint
    constraints(valid_space_slug) do
      get "/:space_slug/:access_pass_slug/purchase", to: "purchases#new", as: :new_space_access_pass_purchase
      post "/:space_slug/:access_pass_slug/purchase", to: "purchases#create", as: :space_access_pass_purchase
    end

    # Waitlist routes - WITH valid_space_slug constraint
    constraints(valid_space_slug) do
      get "/:space_slug/:access_pass_slug/waitlist", to: "waitlist_entries#new", as: :new_waitlist_entry
      post "/:space_slug/:access_pass_slug/waitlist", to: "waitlist_entries#create", as: :waitlist_entries
      get "/:space_slug/:access_pass_slug/waitlist/success", to: "waitlist_entries#success", as: :waitlist_success
    end

    # Stripe webhook endpoint
    post "/webhooks/stripe", to: "purchases#stripe_webhook"

    # Experience routes moved to top of public scope for highest priority

    # CATCH-ALL ROUTES - These must be absolutely last!
    # Space routes at root level for clean URLs (backstagepass.com/space-slug)
    # Access pass routes nested under spaces (backstagepass.com/space-slug/access-pass-slug)

    # Access pass nested under space (must come before single space route)
    constraints(valid_space_slug) do
      get "/:space_slug/:access_pass_slug", to: "access_passes#show",
        constraints: {access_pass_slug: /[a-zA-Z0-9_-]+/},
        as: :public_space_access_pass
    end

    # Space show page (must be absolutely last)
    constraints(valid_space_slug) do
      get "/:space_slug", to: "spaces#show", as: :public_space
    end
  end
end
