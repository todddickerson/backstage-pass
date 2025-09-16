// app/javascript/controllers/bridge/authentication_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    platform: String,
    isAuthenticated: Boolean,
    userEmail: String,
    userId: String
  }

  connect() {
    console.log("Authentication bridge connected", {
      platform: this.platformValue,
      isAuthenticated: this.isAuthenticatedValue
    })

    // Register with the native app if available
    if (this.isNativeApp()) {
      this.registerWithNativeApp()
    }
  }

  // Called when user successfully logs in
  handleLogin(event) {
    const { email, userId, authToken } = event.detail

    if (this.isNativeApp()) {
      // Send credentials to native app for secure storage
      this.storeCredentialsNatively({
        email,
        userId,
        authToken,
        timestamp: new Date().toISOString()
      })
    }

    // Redirect to dashboard after successful login
    if (event.detail.redirectUrl) {
      window.location.href = event.detail.redirectUrl
    } else {
      Turbo.visit("/account/dashboard")
    }
  }

  // Called when user logs out
  handleLogout() {
    if (this.isNativeApp()) {
      // Clear native stored credentials
      this.clearNativeCredentials()
    }

    // Redirect to home page
    Turbo.visit("/")
  }

  // Request biometric authentication (Face ID / Touch ID / Fingerprint)
  async requestBiometric() {
    if (!this.isNativeApp()) {
      console.warn("Biometric authentication only available in native apps")
      return false
    }

    try {
      const result = await this.bridgeCall("requestBiometricAuth", {
        reason: "Authenticate to access your account",
        fallbackToPasscode: true
      })

      if (result.success) {
        // Biometric auth successful, retrieve stored credentials
        const credentials = await this.bridgeCall("getStoredCredentials")
        
        if (credentials && credentials.authToken) {
          // Submit auth token to server
          this.submitAuthToken(credentials.authToken)
        }
      }

      return result.success
    } catch (error) {
      console.error("Biometric authentication failed:", error)
      return false
    }
  }

  // Submit auth token to server for verification
  async submitAuthToken(token) {
    const response = await fetch("/api/v1/auth/verify_token", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCSRFToken()
      },
      body: JSON.stringify({ auth_token: token })
    })

    if (response.ok) {
      const data = await response.json()
      if (data.success) {
        // Authentication successful, reload the page
        Turbo.visit(data.redirect_url || "/account/dashboard")
      } else {
        // Token invalid, show login form
        this.showLoginForm()
      }
    }
  }

  // Check if saved credentials exist in native app
  async checkSavedCredentials() {
    if (!this.isNativeApp()) return false

    try {
      const result = await this.bridgeCall("hasStoredCredentials")
      
      if (result.exists) {
        // Show biometric prompt button
        this.showBiometricOption()
      }

      return result.exists
    } catch (error) {
      console.error("Failed to check stored credentials:", error)
      return false
    }
  }

  // Store credentials securely in native keychain/keystore
  async storeCredentialsNatively(credentials) {
    if (!this.isNativeApp()) return

    try {
      await this.bridgeCall("storeCredentials", credentials)
      console.log("Credentials stored securely in native app")
    } catch (error) {
      console.error("Failed to store credentials:", error)
    }
  }

  // Clear stored credentials from native app
  async clearNativeCredentials() {
    if (!this.isNativeApp()) return

    try {
      await this.bridgeCall("clearCredentials")
      console.log("Native credentials cleared")
    } catch (error) {
      console.error("Failed to clear credentials:", error)
    }
  }

  // Register this page with the native app
  registerWithNativeApp() {
    const registration = {
      controller: "authentication",
      platform: this.platformValue,
      isAuthenticated: this.isAuthenticatedValue,
      capabilities: [
        "biometric",
        "keychain",
        "passwordless"
      ]
    }

    if (window.HotwireNative) {
      window.HotwireNative.register(registration)
    }
  }

  // Show biometric authentication option
  showBiometricOption() {
    const biometricButton = document.getElementById("biometric-auth-button")
    if (biometricButton) {
      biometricButton.classList.remove("hidden")
    }
  }

  // Show standard login form
  showLoginForm() {
    const loginForm = document.getElementById("login-form")
    if (loginForm) {
      loginForm.classList.remove("hidden")
    }
  }

  // Helper: Check if running in native app
  isNativeApp() {
    return this.platformValue === "ios" || this.platformValue === "android"
  }

  // Helper: Bridge communication with native app
  async bridgeCall(method, params = {}) {
    if (window.HotwireNative && window.HotwireNative.bridge) {
      return window.HotwireNative.bridge.call("authentication", method, params)
    } else if (this.platformValue === "ios" && window.webkit?.messageHandlers?.authentication) {
      return new Promise((resolve) => {
        const callbackId = Math.random().toString(36).substr(2, 9)
        window.authenticationCallbacks = window.authenticationCallbacks || {}
        window.authenticationCallbacks[callbackId] = resolve
        
        window.webkit.messageHandlers.authentication.postMessage({
          method,
          params,
          callbackId
        })
      })
    } else if (this.platformValue === "android" && window.AndroidBridge?.authentication) {
      const result = window.AndroidBridge.authentication[method](JSON.stringify(params))
      return JSON.parse(result)
    }

    console.warn("Native bridge not available")
    return null
  }

  // Helper: Get CSRF token
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}