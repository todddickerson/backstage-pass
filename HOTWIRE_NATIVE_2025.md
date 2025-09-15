# Hotwire Native 2025 Architecture - Backstage Pass

Based on Joe Masilotti's latest patterns and Rails World 2025 developments.

## Key 2025 Updates

### Simplified Setup (<20 lines of code!)

The transition from Turbo Native to Hotwire Native has dramatically reduced boilerplate. What used to require hundreds of lines now takes fewer than 20.

### iOS Setup (Swift)

```swift
import HotwireNative
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    private let rootURL = URL(string: "https://backstagepass.app")!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = Navigator(rootURL: rootURL)
        window?.makeKeyAndVisible()
    }
}
```

That's it for basic setup! The Navigator (formerly TurboNavigator) is now built-in.

### Android Setup (Kotlin)

```kotlin
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration

class MainActivity : HotwireActivity() {
    override fun navigatorConfiguration() = NavigatorConfiguration(
        name = "main",
        startLocation = "https://backstagepass.app"
    )
}
```

## Path Configuration (Critical for Navigation)

Path configuration is now the primary way to control navigation behavior. Store this at `/config/hotwire_native/path_configuration.json`:

```json
{
  "settings": {
    "app_name": "Backstage Pass",
    "show_navigation_bar": true,
    "enable_pull_to_refresh": true
  },
  "rules": [
    {
      "patterns": ["/new$", "/edit$"],
      "properties": {
        "presentation": "modal",
        "pull_to_refresh_enabled": false
      }
    },
    {
      "patterns": ["/account/purchased_spaces/.*/experiences/.*/stream"],
      "properties": {
        "presentation": "replace",
        "view_controller": "stream",
        "pull_to_refresh_enabled": false
      }
    },
    {
      "patterns": ["/account/waitlist_entries"],
      "properties": {
        "presentation": "modal",
        "title": "Waitlist Review"
      }
    },
    {
      "patterns": ["/sign_in", "/sign_up", "/password"],
      "properties": {
        "presentation": "modal",
        "view_controller": "authentication"
      }
    }
  ]
}
```

## Bridge Components (2025 Pattern)

Bridge components now inherit from `BridgeComponent` and follow a structured pattern:

### JavaScript Side (Stimulus)

```javascript
// app/javascript/controllers/native/video_controller.js
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "video-player"
  static targets = ["player"]
  
  connect() {
    super.connect()
    
    if (this.platformOptingOut) { 
      // Use web player
      this.initializeWebPlayer()
    } else {
      // Send to native
      this.send("play", {
        url: this.data.get("stream-url"),
        token: this.data.get("livekit-token"),
        streamId: this.data.get("stream-id")
      })
    }
  }
  
  // Receive messages from native
  onMessage(message) {
    switch(message.name) {
      case "stream-ended":
        this.handleStreamEnd()
        break
      case "error":
        this.showError(message.data.error)
        break
    }
  }
}
```

### iOS Native Side

```swift
import HotwireNative
import LiveKit

final class VideoPlayerComponent: BridgeComponent {
    override class var name: String { "video-player" }
    
    override func onReceive(message: Message) {
        guard let data = message.data else { return }
        
        switch message.name {
        case "play":
            playStream(
                url: data["url"] as? String ?? "",
                token: data["token"] as? String ?? "",
                streamId: data["streamId"] as? String ?? ""
            )
        default:
            break
        }
    }
    
    private func playStream(url: String, token: String, streamId: String) {
        let videoVC = LiveKitVideoViewController(
            url: url,
            token: token,
            streamId: streamId
        )
        
        delegate.presentNativeController(videoVC)
    }
}
```

### Android Native Side

```kotlin
import dev.hotwire.navigation.bridge.BridgeComponent
import dev.hotwire.navigation.bridge.Message
import io.livekit.android.LiveKit

class VideoPlayerComponent(
    name: String,
    private val delegate: BridgeDelegate
) : BridgeComponent<NavDestination>(name, delegate) {
    
    override fun onReceive(message: Message) {
        when (message.event) {
            "play" -> {
                val url = message.data?.get("url") as? String ?: return
                val token = message.data?.get("token") as? String ?: return
                val streamId = message.data?.get("streamId") as? String ?: return
                
                playStream(url, token, streamId)
            }
        }
    }
    
    private fun playStream(url: String, token: String, streamId: String) {
        val intent = LiveKitVideoActivity.newIntent(
            delegate.activity,
            url,
            token,
            streamId
        )
        delegate.activity.startActivity(intent)
    }
}
```

## Authentication Pattern (2025)

Authentication now uses a specialized failure app pattern:

```ruby
# app/controllers/turbo_failure_app.rb
class TurboFailureApp < Devise::FailureApp
  def respond
    if hotwire_native_app?
      http_auth
    else
      super
    end
  end

  def http_auth
    self.status = 401
    self.headers["WWW-Authenticate"] = %(Bearer realm="Application")
    self.content_type = "application/json"
    self.response_body = { error: i18n_message }.to_json
  end

  private

  def hotwire_native_app?
    request.user_agent.to_s.include?("Hotwire Native")
  end
end

# config/initializers/devise.rb
config.warden do |manager|
  manager.failure_app = TurboFailureApp
end
```

## Tab Navigation (Simplified)

```swift
// iOS - Just 15 lines for tabs!
class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spaces = Navigator(rootURL: URL(string: "/account/purchased_spaces")!)
        spaces.tabBarItem = UITabBarItem(title: "Spaces", image: UIImage(systemName: "square.grid.2x2"), tag: 0)
        
        let streams = Navigator(rootURL: URL(string: "/account/streams")!)
        streams.tabBarItem = UITabBarItem(title: "Live", image: UIImage(systemName: "video"), tag: 1)
        
        let profile = Navigator(rootURL: URL(string: "/account/profile")!)
        profile.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), tag: 2)
        
        viewControllers = [spaces, streams, profile]
    }
}
```

## Form Handling (Modal Pattern)

Forms ending in `/new` or `/edit` automatically present as modals via path configuration. Rails controllers handle dismissal:

```ruby
# app/controllers/account/access_passes_controller.rb
class Account::AccessPassesController < Account::ApplicationController
  def create
    @access_pass = current_team.access_passes.build(access_pass_params)
    
    if @access_pass.save
      # Hotwire Native will dismiss modal and refresh previous screen
      redirect_to account_space_path(@access_pass.space), 
                  status: :see_other,
                  notice: "Access Pass created!"
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

## Push Notifications (2025 Pattern)

```javascript
// app/javascript/controllers/native/push_controller.js
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "push-notifications"
  
  connect() {
    super.connect()
    this.requestPermission()
  }
  
  requestPermission() {
    this.send("requestPermission")
  }
  
  onMessage(message) {
    if (message.name === "token") {
      // Send token to Rails
      fetch('/account/push_tokens', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          token: message.data.token,
          platform: message.data.platform
        })
      })
    }
  }
  
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content
  }
}
```

## LiveKit Video Integration (Backstage Pass Specific)

Since LiveKit streaming requires native players for performance, we use a specialized bridge:

```ruby
# app/views/account/experiences/stream.html.erb
<div data-controller="native--video"
     data-native--video-stream-url-value="<%= @stream.livekit_url %>"
     data-native--video-livekit-token-value="<%= @stream.generate_token(current_user) %>"
     data-native--video-stream-id-value="<%= @stream.id %>"
     data-bridge-platform="<%= hotwire_native_app? ? 'mobile' : 'web' %>">
  
  <% if hotwire_native_app? %>
    <!-- Native player will take over -->
    <div class="text-center py-8">
      <p>Loading stream...</p>
    </div>
  <% else %>
    <!-- Web player fallback -->
    <div id="livekit-video-container"></div>
  <% end %>
</div>
```

## GetStream.io Chat (Works in WebView)

Chat can remain in the web view since GetStream.io handles it well:

```erb
<!-- app/views/account/experiences/_chat.html.erb -->
<div data-controller="chat"
     data-chat-api-key-value="<%= Rails.application.credentials.getstream[:api_key] %>"
     data-chat-token-value="<%= current_user.chat_token %>"
     data-chat-channel-id-value="<%= @experience.chat_channel_id %>">
  
  <div id="chat-container" class="h-64 overflow-y-auto">
    <!-- GetStream.io SDK renders here -->
  </div>
  
  <% unless hotwire_native_app? %>
    <!-- Web gets inline input -->
    <input type="text" 
           data-chat-target="input"
           data-action="keydown.enter->chat#send"
           class="w-full p-2 border rounded"
           placeholder="Type a message...">
  <% end %>
</div>
```

For mobile, we can optionally move the input to a native navigation bar button.

## Development Workflow (2025)

### 1. Start with Rails App
```bash
# Ensure mobile-friendly views
rails generate hotwire:native:install

# This adds:
# - app/views/hotwire/native/navigation.html.erb
# - config/hotwire_native/path_configuration.json
# - User agent detection helpers
```

### 2. Add iOS App
```bash
# Generate iOS app (uses template)
rails generate hotwire:native:ios

cd ios
open BackstagePass.xcodeproj
# Add LiveKit SDK via Swift Package Manager
# Build and run
```

### 3. Add Android App
```bash
# Generate Android app
rails generate hotwire:native:android

cd android
# Add to app/build.gradle:
# implementation 'io.livekit:livekit-android:1.5.0'
./gradlew build
```

## Testing Strategy (2025)

### Rails System Tests Work for Mobile Too!

```ruby
# test/system/mobile/stream_test.rb
class Mobile::StreamTest < ApplicationSystemTestCase
  setup do
    # Fake the Hotwire Native user agent
    page.driver.header("User-Agent", "Hotwire Native iOS")
  end
  
  test "native video player launches for stream" do
    sign_in @user
    visit account_experience_stream_path(@experience)
    
    # Should see native player placeholder
    assert_selector "[data-controller='native--video']"
    assert_selector "[data-bridge-platform='mobile']"
    
    # Should not see web player
    assert_no_selector "#livekit-video-container"
  end
end
```

## Key Differences from Original Phase 1b Spec

### ✅ Improvements Based on 2025 Patterns

1. **Massively Simplified Setup** - 20 lines vs 100+ lines
2. **Path Configuration** - Declarative navigation control
3. **Bridge Components** - Structured pattern with BridgeComponent base
4. **Built-in Navigator** - No need for custom navigation code
5. **Authentication Pattern** - TurboFailureApp for mobile auth
6. **Form Modals** - Automatic via path configuration

### 🔄 Updates to Implementation

1. **Remove Boilerplate** - Most custom navigation code unnecessary
2. **Use Path Config** - For modals, tabs, and navigation rules
3. **Leverage Bridge Components** - For native features only
4. **Simplified Tab Setup** - 15 lines for complete tab navigation
5. **Rails-First Testing** - System tests with user agent spoofing

### 📱 LiveKit Integration Remains Native

Video streaming still requires native players for performance:
- WebRTC has ~30% worse performance in WebView
- Native LiveKit SDKs required for both platforms
- Bridge pattern for communication
- GetStream.io chat can stay in WebView

## Recommended Implementation Order

1. **Week 1-4: Rails App** (unchanged)
   - Build complete web app
   - Ensure mobile-responsive
   - Add Hotwire Native helpers

2. **Week 5: iOS App**
   - Basic setup (20 lines)
   - Path configuration
   - LiveKit native player
   - Push notifications
   - TestFlight

3. **Week 6: Android App**
   - Basic setup
   - Path configuration  
   - LiveKit native player
   - Push notifications
   - Internal testing

## Resources

- Joe Masilotti's Book: "Hotwire Native for Rails Developers" (Sept 2025)
- Tutorial Series: https://masilotti.com/hotwire-native-by-example/
- Bridge Components: https://github.com/hotwired/hotwire-native-bridge
- Official Docs: https://native.hotwired.dev

---

This architecture leverages the latest 2025 patterns from Joe Masilotti and Rails World, dramatically simplifying our mobile implementation while maintaining native performance for video streaming.