# ⚠️ DEPRECATED - See HOTWIRE_NATIVE_2025.md

**This document is outdated as of Rails World 2025. Please use:**

## 📍 **[HOTWIRE_NATIVE_2025.md](./HOTWIRE_NATIVE_2025.md)** for current implementation

### Why this is deprecated:
- Hotwire Native setup is now <20 lines (was 100+ lines)
- Path configuration replaces most native code
- BridgeComponent pattern supersedes old bridge approach
- Navigator is built-in (no more TurboNavigator)
- Joe Masilotti's patterns from Rails World 2025 are the standard

---

# [ARCHIVED] Hotwire Native Mobile Implementation Guide

## Quick Start: From Rails to App Store in 2 Weeks

### Week 1: iOS App

#### Day 1: Setup & Configuration

```bash
# 1. Add Hotwire Native gem
bundle add turbo-native-initializer

# 2. Generate iOS app
rails generate hotwire:native:ios

# 3. Configure native paths
cat > config/initializers/hotwire_native.rb << 'RUBY'
Rails.application.config.hotwire_native = {
  # Define which paths should use native navigation
  native_paths: [
    /^\/account\/streams\/\d+\/broadcast/,  # Native video player
    /^\/account\/spaces\/\d+\/live/,        # Live streaming
    /^\/purchase/,                          # Native Apple/Google Pay
  ],
  
  # Tab bar configuration
  tabs: [
    { title: "Home", path: "/", icon: "house" },
    { title: "Spaces", path: "/spaces", icon: "building.2.crop.circle" },
    { title: "Live", path: "/live", icon: "video.circle.fill" },
    { title: "Profile", path: "/account", icon: "person.circle" }
  ]
}
RUBY

# 4. Create path configuration
cat > ios/BackstagePass/path_configuration.json << 'JSON'
{
  "settings": {
    "screenshots_enabled": true,
    "pull_to_refresh_enabled": true
  },
  "rules": [
    {
      "patterns": ["/account/streams/*/broadcast"],
      "properties": {
        "presentation": "modal",
        "pull_to_refresh_enabled": false,
        "bridge": "streaming"
      }
    },
    {
      "patterns": ["/spaces/*/live"],
      "properties": {
        "presentation": "fullscreen",
        "bridge": "streaming"
      }
    },
    {
      "patterns": ["/purchase/*"],
      "properties": {
        "presentation": "modal",
        "bridge": "payment"
      }
    }
  ]
}
JSON
```

#### Day 2: Native Bridges Implementation

```swift
// ios/BackstagePass/Bridges/StreamingBridge.swift
import HotwireNative
import LiveKit
import UIKit

class StreamingBridge: BridgeComponent {
    override class var name: String { "streaming" }
    
    private var room: Room?
    private var videoView: VideoView?
    private var localVideoTrack: LocalVideoTrack?
    private var localAudioTrack: LocalAudioTrack?
    
    // MARK: - Bridge Methods
    
    @objc func initializeStream(_ message: BridgeMessage) {
        guard let token = message.data["token"] as? String,
              let roomName = message.data["room"] as? String else {
            message.failure(error: "Missing required parameters")
            return
        }
        
        Task {
            do {
                // Setup LiveKit room
                room = Room(
                    delegate: self,
                    options: RoomOptions(
                        adaptiveStream: true,
                        dynacast: true,
                        defaultCameraCaptureOptions: CameraCaptureOptions(
                            dimensions: .h720_169,
                            fps: 30
                        )
                    )
                )
                
                // Connect to room
                try await room!.connect(
                    url: "wss://livekit.backstagepass.app",
                    token: token
                )
                
                // Setup local tracks for broadcaster
                if message.data["role"] as? String == "host" {
                    await setupBroadcaster()
                }
                
                message.success(data: ["status": "connected", "room": roomName])
                
            } catch {
                message.failure(error: error.localizedDescription)
            }
        }
    }
    
    @objc func handleDoubleTap(_ message: BridgeMessage) {
        guard let x = message.data["x"] as? CGFloat,
              let y = message.data["y"] as? CGFloat else {
            return
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
        
        // Show heart animation
        showHeartAnimation(at: CGPoint(x: x, y: y))
        
        // Send like through data channel
        let likeData = [
            "type": "like",
            "userId": message.data["userId"] as? String ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: likeData) {
            room?.localParticipant?.publishData(jsonData, reliability: .reliable)
        }
        
        message.success()
    }
    
    @objc func toggleCamera(_ message: BridgeMessage) {
        Task {
            guard let localVideoTrack = localVideoTrack else { return }
            
            let isEnabled = await localVideoTrack.isEnabled
            try await localVideoTrack.set(enabled: !isEnabled)
            
            message.success(data: ["enabled": !isEnabled])
        }
    }
    
    @objc func toggleMicrophone(_ message: BridgeMessage) {
        Task {
            guard let localAudioTrack = localAudioTrack else { return }
            
            let isEnabled = await localAudioTrack.isEnabled
            try await localAudioTrack.set(enabled: !isEnabled)
            
            message.success(data: ["enabled": !isEnabled])
        }
    }
    
    @objc func switchCamera(_ message: BridgeMessage) {
        Task {
            guard let localVideoTrack = localVideoTrack as? LocalCameraTrack else { return }
            
            let currentPosition = await localVideoTrack.captureOptions.position
            let newPosition: AVCaptureDevice.Position = currentPosition == .front ? .back : .front
            
            try await localVideoTrack.switchCameraPosition(to: newPosition)
            message.success()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBroadcaster() async {
        do {
            // Create local tracks
            let camera = Room.createCameraTrack()
            let microphone = Room.createMicrophoneTrack()
            
            self.localVideoTrack = try await camera.get()
            self.localAudioTrack = try await microphone.get()
            
            // Publish tracks
            if let room = room {
                try await room.localParticipant?.publish(videoTrack: localVideoTrack!)
                try await room.localParticipant?.publish(audioTrack: localAudioTrack!)
            }
            
            // Setup video view
            await MainActor.run {
                setupVideoView()
            }
        } catch {
            print("Failed to setup broadcaster: \(error)")
        }
    }
    
    @MainActor
    private func setupVideoView() {
        guard let webView = delegate.webView,
              let videoTrack = localVideoTrack else { return }
        
        // Create video view
        videoView = VideoView()
        videoView?.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to web view
        webView.addSubview(videoView!)
        
        // Setup constraints (picture-in-picture style)
        NSLayoutConstraint.activate([
            videoView!.widthAnchor.constraint(equalToConstant: 120),
            videoView!.heightAnchor.constraint(equalToConstant: 160),
            videoView!.topAnchor.constraint(equalTo: webView.safeAreaLayoutGuide.topAnchor, constant: 20),
            videoView!.trailingAnchor.constraint(equalTo: webView.trailingAnchor, constant: -20)
        ])
        
        // Attach video track
        videoView?.track = videoTrack
    }
    
    @MainActor
    private func showHeartAnimation(at point: CGPoint) {
        guard let webView = delegate.webView else { return }
        
        let heartLabel = UILabel()
        heartLabel.text = "❤️"
        heartLabel.font = .systemFont(ofSize: 30)
        heartLabel.center = point
        heartLabel.alpha = 1.0
        
        webView.addSubview(heartLabel)
        
        // Animate upward and fade out
        UIView.animate(withDuration: 2.0, animations: {
            heartLabel.center.y -= 100
            heartLabel.alpha = 0
            heartLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { _ in
            heartLabel.removeFromSuperview()
        }
    }
}

// MARK: - Room Delegate

extension StreamingBridge: RoomDelegate {
    func room(_ room: Room, didUpdate connectionState: ConnectionState) {
        // Notify web view of connection state changes
        delegate.reply(to: "connectionStateChanged", with: ["state": connectionState.rawValue])
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didPublish publication: RemoteTrackPublication) {
        // Handle remote participant publishing
        delegate.reply(to: "participantJoined", with: ["participantId": participant.identity])
    }
    
    func room(_ room: Room, data: Data, participant: RemoteParticipant?) {
        // Handle data channel messages
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            delegate.reply(to: "dataReceived", with: json)
        }
    }
}
```

#### Day 3: Payment Bridge (Apple Pay)

```swift
// ios/BackstagePass/Bridges/PaymentBridge.swift
import HotwireNative
import PassKit
import Stripe

class PaymentBridge: BridgeComponent {
    override class var name: String { "payment" }
    
    @objc func setupApplePay(_ message: BridgeMessage) {
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            message.failure(error: "Apple Pay not available")
            return
        }
        
        let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex]
        
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
            message.success(data: ["available": true])
        } else {
            message.success(data: ["available": false, "reason": "No cards added"])
        }
    }
    
    @objc func processPayment(_ message: BridgeMessage) {
        guard let amount = message.data["amount"] as? Double,
              let currency = message.data["currency"] as? String,
              let description = message.data["description"] as? String else {
            message.failure(error: "Invalid payment parameters")
            return
        }
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.app.backstagepass"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US"
        request.currencyCode = currency
        
        let item = PKPaymentSummaryItem(
            label: description,
            amount: NSDecimalNumber(value: amount)
        )
        request.paymentSummaryItems = [item]
        
        let controller = PKPaymentAuthorizationViewController(paymentRequest: request)
        controller?.delegate = self
        
        if let controller = controller {
            delegate.present(controller) { presented in
                if !presented {
                    message.failure(error: "Could not present payment sheet")
                }
            }
        }
    }
}

extension PaymentBridge: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Process with Stripe
        STPAPIClient.shared.createPaymentMethod(with: payment) { paymentMethod, error in
            if let error = error {
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            } else if let paymentMethod = paymentMethod {
                // Send to Rails backend
                self.confirmPayment(paymentMethodId: paymentMethod.stripeId) { success in
                    let status: PKPaymentAuthorizationStatus = success ? .success : .failure
                    completion(PKPaymentAuthorizationResult(status: status, errors: nil))
                }
            }
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
    }
}
```

#### Day 4-5: UI Polish & Testing

```swift
// ios/BackstagePass/Controllers/MainViewController.swift
import HotwireNative
import UIKit

class MainViewController: UITabBarController {
    private let navigator = Navigator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        configureAppearance()
    }
    
    private func setupTabs() {
        let tabs = [
            createTab(title: "Home", icon: "house", path: "/"),
            createTab(title: "Spaces", icon: "building.2.crop.circle", path: "/spaces"),
            createTab(title: "Live", icon: "video.circle.fill", path: "/live"),
            createTab(title: "Profile", icon: "person.circle", path: "/account")
        ]
        
        viewControllers = tabs
    }
    
    private func createTab(title: String, icon: String, path: String) -> UINavigationController {
        let session = Session(webView: WKWebView(frame: .zero))
        session.pathConfiguration = PathConfiguration(file: "path_configuration.json")
        
        let viewController = VisitableViewController(url: URL(string: "\(baseURL)\(path)")!)
        viewController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: icon),
            selectedImage: UIImage(systemName: "\(icon).fill")
        )
        
        let navController = UINavigationController(rootViewController: viewController)
        navigator.session = session
        navigator.modalSession = Session(webView: WKWebView(frame: .zero))
        
        return navController
    }
    
    private func configureAppearance() {
        // Match Rails app styling
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(hex: "#6B46C1") // Purple from Tailwind
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Tab bar
        UITabBar.appearance().tintColor = UIColor(hex: "#6B46C1")
    }
}
```

### Week 2: Android App & Cross-Platform Testing

#### Day 1: Android Setup

```kotlin
// android/app/src/main/java/app/backstagepass/MainActivity.kt
package app.backstagepass

import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import android.os.Bundle

class MainActivity : HotwireActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureNavigator()
    }
    
    private fun configureNavigator() {
        val configuration = NavigatorConfiguration(
            name = "main",
            startLocation = "$BASE_URL/",
            pathConfiguration = PathConfiguration(assetPath = "path_configuration.json")
        )
        
        navigator.registerBridge(StreamingBridge::class)
        navigator.registerBridge(PaymentBridge::class)
        navigator.start(configuration)
    }
    
    companion object {
        const val BASE_URL = BuildConfig.BASE_URL
    }
}

// android/app/src/main/java/app/backstagepass/bridges/StreamingBridge.kt
package app.backstagepass.bridges

import dev.hotwire.navigation.bridge.Bridge
import dev.hotwire.navigation.bridge.BridgeDelegate
import dev.hotwire.navigation.bridge.Message
import io.livekit.android.LiveKit
import io.livekit.android.room.Room
import io.livekit.android.room.participant.Participant
import android.view.HapticFeedbackConstants
import kotlinx.coroutines.launch

class StreamingBridge(delegate: BridgeDelegate) : Bridge(delegate) {
    private var room: Room? = null
    
    override val name = "streaming"
    
    @BridgeMethod
    fun initializeStream(message: Message) {
        val token = message.data["token"] as? String ?: run {
            message.failure("Missing token")
            return
        }
        
        lifecycleScope.launch {
            try {
                room = LiveKit.create(
                    appContext = delegate.applicationContext,
                    options = RoomOptions(
                        adaptiveStream = true,
                        dynacast = true
                    )
                )
                
                room?.connect(
                    url = "wss://livekit.backstagepass.app",
                    token = token
                )
                
                message.success(mapOf("status" to "connected"))
            } catch (e: Exception) {
                message.failure(e.message ?: "Connection failed")
            }
        }
    }
    
    @BridgeMethod
    fun handleDoubleTap(message: Message) {
        // Haptic feedback
        delegate.webView?.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        
        // Send like
        val likeData = """
            {"type":"like","userId":"${message.data["userId"]}","timestamp":${System.currentTimeMillis()}}
        """.toByteArray()
        
        room?.localParticipant?.publishData(likeData, reliable = true)
        
        // Show animation
        showHeartAnimation(
            message.data["x"] as? Float ?: 0f,
            message.data["y"] as? Float ?: 0f
        )
        
        message.success()
    }
}
```

#### Day 2-3: Feature Parity & Testing

```ruby
# test/system/mobile_test.rb
require "application_system_test_case"

class MobileSystemTest < ApplicationSystemTestCase
  setup do
    # Simulate mobile user agent
    Capybara.current_session.driver.header(
      'User-Agent',
      'Turbo Native iOS'
    )
  end
  
  test "mobile optimized views load correctly" do
    space = create(:space, :published)
    
    visit space_path(space)
    
    # Check for mobile-specific elements
    assert_selector "[data-hotwire-native-bridge]"
    assert_selector "[data-platform='ios']"
    
    # Verify native bridge data
    bridge_data = find("[data-bridge='stream-native']")["data-bridge-token"]
    assert bridge_data.present?
  end
  
  test "double tap interaction triggers native bridge" do
    stream = create(:stream, :live)
    sign_in stream.host
    
    visit broadcast_account_stream_path(stream)
    
    # Simulate double tap
    video_element = find("#video-container")
    video_element.double_click
    
    # Check for interaction
    assert_selector ".floating-heart", visible: :all
  end
end
```

## Testing & Debugging

### 1. Local Development with Devices

```ruby
# config/environments/development.rb
Rails.application.configure do
  # Allow mobile devices to connect
  config.hosts << /[a-z0-9-]+\.ngrok\.io/
  config.hosts << /192\.168\.\d+\.\d+/
  
  # Detect Hotwire Native
  config.hotwire.native_user_agent = /Turbo Native/
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  helper_method :hotwire_native_app?, :platform
  
  def hotwire_native_app?
    request.user_agent.to_s.match?(/Turbo Native/)
  end
  
  def platform
    case request.user_agent
    when /Turbo Native iOS/
      'ios'
    when /Turbo Native Android/
      'android'
    else
      'web'
    end
  end
  
  def hotwire_native_bridge_data
    return {} unless hotwire_native_app?
    
    {
      platform: platform,
      version: request.headers['X-Turbo-Native-Version'],
      user_id: current_user&.id,
      session_id: session.id
    }
  end
end
```

### 2. Debug Console for Mobile

```erb
<!-- app/views/layouts/application.html.erb -->
<% if hotwire_native_app? && Rails.env.development? %>
  <div id="mobile-debug" class="fixed bottom-0 left-0 right-0 bg-black text-white text-xs p-2 z-50">
    Platform: <%= platform %> | 
    User: <%= current_user&.email %> |
    <button onclick="window.nativeBridge.send('debug', {action: 'logs'})">
      View Logs
    </button>
  </div>
<% end %>
```

### 3. Performance Monitoring

```ruby
# app/controllers/concerns/mobile_performance.rb
module MobilePerformance
  extend ActiveSupport::Concern
  
  included do
    around_action :track_mobile_performance, if: :hotwire_native_app?
  end
  
  private
  
  def track_mobile_performance
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    yield
    
    duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    
    Rails.logger.info(
      "Mobile Request",
      platform: platform,
      controller: controller_name,
      action: action_name,
      duration: (duration * 1000).round(2),
      user_id: current_user&.id
    )
    
    # Send to analytics
    Analytics.track(
      user_id: current_user&.id,
      event: 'Mobile Page View',
      properties: {
        platform: platform,
        path: request.path,
        duration_ms: (duration * 1000).round(2)
      }
    )
  end
end
```

## Deployment & Distribution

### Beta Testing Setup

```bash
# iOS TestFlight
cd ios
fastlane beta

# Android Beta
cd android
./gradlew bundleRelease
# Upload to Play Console Beta track
```

### App Store Submission Checklist

```markdown
## iOS App Store
- [ ] App icons (all sizes)
- [ ] Launch screens
- [ ] Screenshots (iPhone & iPad)
- [ ] App preview video
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] Export compliance (streaming encryption)
- [ ] Age rating questionnaire
- [ ] In-app purchase setup (if applicable)

## Google Play Store
- [ ] App icons
- [ ] Feature graphic
- [ ] Screenshots (phone & tablet)
- [ ] Short & full description
- [ ] Privacy policy URL
- [ ] Content rating questionnaire
- [ ] Target audience declaration
- [ ] Data safety form
```

## Maintenance & Updates

### Over-the-Air Updates

Since Hotwire Native loads web content, most updates don't require app store releases:

```ruby
# app/controllers/concerns/version_check.rb
module VersionCheck
  extend ActiveSupport::Concern
  
  included do
    before_action :check_app_version, if: :hotwire_native_app?
  end
  
  private
  
  def check_app_version
    native_version = request.headers['X-Turbo-Native-Version']
    minimum_version = Rails.configuration.hotwire_native[:minimum_version]
    
    if native_version && Gem::Version.new(native_version) < Gem::Version.new(minimum_version)
      render json: {
        update_required: true,
        message: "Please update your app to continue",
        store_url: platform == 'ios' ? 
          "https://apps.apple.com/app/backstage-pass/id123456" :
          "https://play.google.com/store/apps/details?id=app.backstagepass"
      }, status: 426 # Upgrade Required
    end
  end
end
```

## Success Metrics for Mobile

Track these KPIs:

```ruby
# app/services/mobile_analytics.rb
class MobileAnalytics
  def self.dashboard
    {
      adoption: {
        ios_users: User.joins(:sessions).where("sessions.user_agent LIKE ?", "%iOS%").distinct.count,
        android_users: User.joins(:sessions).where("sessions.user_agent LIKE ?", "%Android%").distinct.count,
        web_only_users: User.joins(:sessions).where.not("sessions.user_agent LIKE ?", "%Native%").distinct.count
      },
      
      engagement: {
        avg_session_duration_mobile: calculate_avg_session(:mobile),
        avg_session_duration_web: calculate_avg_session(:web),
        double_taps_per_stream: Stream.live.average(:interaction_count)
      },
      
      performance: {
        avg_load_time_ios: PageLoad.ios.average(:duration_ms),
        avg_load_time_android: PageLoad.android.average(:duration_ms),
        crash_rate: calculate_crash_rate
      },
      
      conversion: {
        mobile_purchase_rate: mobile_conversion_rate,
        web_purchase_rate: web_conversion_rate
      }
    }
  end
end
```

## Troubleshooting Common Issues

### Issue: Video not displaying on iOS
```swift
// Ensure info.plist has camera permissions
<key>NSCameraUsageDescription</key>
<string>Camera access is required for live streaming</string>
```

### Issue: Deep links not working
```ruby
# config/routes.rb
direct :deep_link do |model, options|
  "backstagepass://#{model.class.name.downcase}/#{model.id}"
end
```

### Issue: Push notifications not received
```swift
// AppDelegate.swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    // Send to Rails backend
    BackstagePassAPI.shared.registerDeviceToken(token)
}
```