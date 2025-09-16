Rails.application.routes.draw do
  # See `config/routes/*.rb` to customize these configurations.
  draw "concerns"
  draw "devise"
  draw "sidekiq"
  draw "avo"

  # `collection_actions` is automatically super scaffolded to your routes file when creating certain objects.
  # This is helpful to have around when working with shallow routes and complicated model namespacing. We don't use this
  # by default, but sometimes Super Scaffolding will generate routes that use this for `only` and `except` options.
  collection_actions = [:index, :new, :create] # standard:disable Lint/UselessAssignment

  # This helps mark `resources` definitions below as not actually defining the routes for a given resource, but just
  # making it possible for developers to extend definitions that are already defined by the `bullet_train` Ruby gem.
  # TODO Would love to get this out of the application routes file.
  extending = {only: []}

  scope module: "public" do
    # To keep things organized, we put non-authenticated controllers in the `Public::` namespace.
    # The root `/` path is routed to `Public::HomeController#index` by default.
    root to: "home#index"
    
    # Priority routes - these take precedence over catch-all space routes
    # Add static pages here as needed (about, terms, privacy, etc.)
    get "about", to: "pages#about"
    get "terms", to: "pages#terms" 
    get "privacy", to: "pages#privacy"
    
    # Browse all spaces (marketplace index)
    get "explore", to: "spaces#index", as: :explore_spaces
    
    # Creator profile routes (@username) - must come before catch-all routes
    get "/@:username", to: "creator_profiles#show", constraints: { username: /[a-zA-Z0-9_-]+/ }, as: :creator_profile
    
    # CATCH-ALL ROUTES - These must be last!
    # Space routes at root level for clean URLs (backstagepass.com/space-slug)
    # Access pass routes nested under spaces (backstagepass.com/space-slug/access-pass-slug)
    get "/:space_slug/:access_pass_slug", to: "access_passes#show", 
        constraints: { space_slug: /[a-zA-Z0-9_-]+/, access_pass_slug: /[a-zA-Z0-9_-]+/ },
        as: :public_space_access_pass
    
    # Space show page (must be after nested routes)
    get "/:space_slug", to: "spaces#show", 
        constraints: { space_slug: /[a-zA-Z0-9_-]+/ },
        as: :public_space
  end

  namespace :webhooks do
    namespace :incoming do
      namespace :oauth do
        # 🚅 super scaffolding will insert new oauth provider webhooks above this line.
      end
    end
  end

  namespace :api do
    draw "api/v1"
    # 🚅 super scaffolding will insert new api versions above this line.
  end

  namespace :account do
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
          resources :experiences
        end

        resources :access_passes
      end
    end
  end
end
