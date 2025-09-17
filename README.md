# Backstage Pass 🎫

A modern creator economy platform built with Ruby on Rails, enabling creators to monetize exclusive content through live streaming, courses, and community access.

## 🚀 Overview

Backstage Pass empowers creators to build sustainable businesses by providing:
- **Live Streaming** - Real-time video streaming with chat
- **Access Passes** - Flexible monetization models
- **Community Spaces** - Exclusive content areas
- **Mobile First** - Native iOS/Android apps via Turbo Native

## 🛠 Technology Stack

- **Framework**: Ruby on Rails 8.0.2
- **Ruby Version**: 3.3.0
- **Frontend**: Hotwire (Turbo + Stimulus)
- **CSS**: Tailwind CSS
- **Database**: PostgreSQL
- **Cache/Queues**: Redis
- **Background Jobs**: Sidekiq
- **Base Template**: Bullet Train
- **Video Streaming**: LiveKit
- **Chat**: GetStream.io
- **Payments**: Stripe
- **Mobile**: Turbo Native (iOS/Android)

## 📋 Prerequisites

- Ruby 3.3.0
- PostgreSQL 14+
- Redis 6+
- Node.js 18+
- Yarn

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/todddickerson/backstage-pass.git
cd backstage-pass
```

### 2. Install dependencies
```bash
bundle install
yarn install
```

### 3. Set up environment variables
```bash
cp .env.example .env
```

Edit `.env` with your credentials:
```env
# Required Services
STRIPE_SECRET_KEY=sk_test_...
LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
LIVEKIT_WS_URL=wss://...
GETSTREAM_API_KEY=...
GETSTREAM_API_SECRET=...

# Optional Services
POSTMARK_API_TOKEN=...
CLOUDINARY_URL=...
```

### 4. Setup database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 5. Start the application
```bash
bin/dev
```

Visit http://localhost:3000

## 🧪 Testing

Run the test suite:
```bash
# All tests
rails test

# Integration tests only
rails test:integration

# System tests
rails test:system

# With coverage
COVERAGE=true rails test
```

Run linting:
```bash
standardrb --fix
```

## 📱 Mobile Development

### iOS Setup
1. Install Xcode
2. Navigate to `ios/` directory
3. Run `pod install`
4. Open `BackstagePass.xcworkspace` in Xcode
5. Configure signing & capabilities
6. Run on simulator or device

### Android Setup
1. Install Android Studio
2. Navigate to `android/` directory
3. Sync Gradle dependencies
4. Configure signing in `app/build.gradle`
5. Run on emulator or device

## 🏗 Architecture

### Core Models

- **User** - Platform users (creators and viewers)
- **Team** - Organization unit for creators
- **Space** - Creator's content space
- **Experience** - Content types (live stream, course, etc.)
- **Stream** - Individual streaming sessions
- **AccessPass** - Monetization packages
- **AccessGrant** - User access permissions

### Key Features

1. **Multi-tenant Architecture** - Team-based isolation
2. **Real-time Streaming** - LiveKit integration
3. **Chat System** - GetStream.io powered
4. **Payment Processing** - Stripe subscriptions & one-time payments
5. **Mobile Support** - Turbo Native wrapper apps

## 🚢 Deployment

### Railway (Recommended)
```bash
railway login
railway link
railway up
```

### Heroku
```bash
heroku create your-app-name
heroku addons:create heroku-postgresql:hobby-dev
heroku addons:create heroku-redis:hobby-dev
git push heroku main
heroku run rails db:migrate
```

### Environment Variables Required

See `.env.example` for full list. Critical variables:
- Database connection
- Redis connection
- External service API keys
- Rails master key

## 📖 Documentation

- [Creator Guide](docs/creators/README.md) - For content creators
- [Viewer Guide](docs/viewers/README.md) - For audience members
- [Developer Guide](docs/developers/README.md) - For contributors
- [API Documentation](docs/api/README.md) - REST API reference
- [Deployment Guide](docs/deployment/README.md) - Production setup

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Workflow

1. Run preflight checks: `./bin/preflight-check`
2. Make your changes
3. Run tests: `rails test`
4. Run linter: `standardrb --fix`
5. Commit with conventional commits

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on [Bullet Train](https://bullettrain.co) Rails framework
- Streaming powered by [LiveKit](https://livekit.io)
- Chat powered by [GetStream](https://getstream.io)
- Payments powered by [Stripe](https://stripe.com)

## 📞 Support

For issues and questions:
- Open a [GitHub Issue](https://github.com/todddickerson/backstage-pass/issues)
- Check our [FAQ](docs/FAQ.md)
- Email: support@backstagepass.app

---

Built with ❤️ by the Backstage Pass team