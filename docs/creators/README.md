# Creator Guide

Welcome to Backstage Pass! This guide will help you get started as a creator and build your audience.

## Table of Contents

- [Getting Started](#getting-started)
- [Setting Up Your Space](#setting-up-your-space)
- [Creating Access Passes](#creating-access-passes)
- [Managing Experiences](#managing-experiences)
- [Live Streaming](#live-streaming)
- [Chat Moderation](#chat-moderation)
- [Analytics & Insights](#analytics--insights)
- [Payments & Payouts](#payments--payouts)

## Getting Started

### 1. Create Your Account

1. Sign up at [backstagepass.app](https://backstagepass.app)
2. Verify your email address
3. Complete your profile with:
   - Profile photo
   - Bio
   - Social media links

### 2. Create Your Team

Teams are the organizational unit for creators:

```
Your Account
  └── Team (Your Brand)
      └── Space (Content Area)
          ├── Experiences (Live Streams, Courses)
          └── Access Passes (Monetization)
```

## Setting Up Your Space

A Space is your dedicated content area where fans can access your exclusive content.

### Creating Your First Space

1. Navigate to **Dashboard → Spaces**
2. Click **New Space**
3. Fill in:
   - **Space Name**: Your brand or content area name
   - **Slug**: URL-friendly identifier (e.g., `your-brand`)
   - **Description**: What fans can expect
   - **Cover Image**: Eye-catching banner

### Space Settings

- **Privacy**: Public or invite-only
- **Categories**: Tag your content type
- **Links**: Social media and website

## Creating Access Passes

Access Passes are how you monetize your content. Create different tiers for different levels of access.

### Types of Access Passes

1. **One-Time Purchase**
   - Single payment for permanent access
   - Good for courses or special events
   
2. **Subscription**
   - Monthly or annual recurring payments
   - Perfect for ongoing content

3. **Limited Time**
   - Access expires after X days
   - Great for trials or workshops

### Creating an Access Pass

```ruby
# Example Access Pass Structure
{
  name: "VIP Membership",
  price_cents: 2999,  # $29.99
  pricing_type: "monthly",
  duration_days: nil,  # Ongoing
  features: [
    "All live streams",
    "Exclusive content",
    "Private Discord",
    "Monthly Q&A"
  ]
}
```

### Pricing Strategies

- **Tiered Pricing**: Basic ($9), Pro ($29), VIP ($99)
- **Early Bird**: Discounts for first 100 members
- **Bundle Deals**: Multiple experiences for one price

## Managing Experiences

Experiences are the content types you offer within your Space.

### Experience Types

1. **Live Stream** 🎥
   - Real-time video broadcasting
   - Interactive chat
   - Scheduled or spontaneous

2. **Course** 📚
   - Pre-recorded lessons
   - Structured curriculum
   - Progress tracking

3. **Community** 👥
   - Ongoing access
   - Member discussions
   - Exclusive posts

4. **Consultation** 💼
   - 1-on-1 sessions
   - Group workshops
   - Office hours

5. **Digital Product** 📦
   - Downloadable content
   - Templates, presets
   - E-books, guides

### Creating an Experience

1. Navigate to your Space
2. Click **New Experience**
3. Select type and configure:
   - Name and description
   - Price (or included in Access Pass)
   - Schedule (if applicable)

## Live Streaming

### Before Going Live

1. **Test Your Setup**
   - Camera and microphone
   - Internet connection (5+ Mbps upload)
   - Lighting and background

2. **Schedule Your Stream**
   - Set date and time
   - Add to calendar
   - Notify subscribers

3. **Prepare Content**
   - Outline or script
   - Screen shares ready
   - Backup plan

### Starting a Stream

```bash
1. Go to Experience → Streams
2. Click "Start Stream"
3. Allow camera/microphone access
4. Click "Go Live"
```

### During the Stream

- **Engage with Chat**: Respond to questions
- **Use Overlays**: Display information
- **Record Locally**: Backup recording
- **Monitor Stats**: Viewer count, quality

### After Streaming

- Stream automatically saves for replay
- Download recording for editing
- Review analytics
- Follow up with viewers

## Chat Moderation

### Moderation Tools

- **Auto-moderation**: Filter spam and inappropriate content
- **Trusted Users**: Give moderation powers to loyal fans
- **Slow Mode**: Limit message frequency
- **Subscriber-Only**: Restrict chat to paying members

### Best Practices

1. Set clear community guidelines
2. Appoint trusted moderators
3. Use keyword filters
4. Address issues quickly
5. Reward positive behavior

## Analytics & Insights

### Key Metrics

- **Revenue Metrics**
  - Monthly recurring revenue (MRR)
  - Average revenue per user (ARPU)
  - Churn rate
  - Lifetime value (LTV)

- **Engagement Metrics**
  - Stream views and duration
  - Chat participation
  - Content completion rates
  - Member retention

- **Growth Metrics**
  - New subscribers
  - Conversion rate
  - Traffic sources
  - Social shares

### Using Analytics

1. **Identify Trends**: What content performs best?
2. **Optimize Timing**: When is your audience active?
3. **Test Pricing**: A/B test different tiers
4. **Improve Content**: Based on feedback

## Payments & Payouts

### Payment Processing

- Powered by Stripe
- Accepts all major cards
- International payments
- Automatic currency conversion

### Payout Schedule

- **Standard**: Weekly on Fridays
- **Express**: Daily (additional fee)
- **Minimum**: $10 for payout

### Tax Information

1. Complete W-9 (US) or W-8 (International)
2. Track income for tax purposes
3. Download 1099 forms (US creators)
4. Consult tax professional

### Best Practices

- Keep payment info updated
- Monitor failed payments
- Offer payment plan options
- Communicate price changes early

## Tips for Success

### Content Strategy

1. **Consistency is Key**: Regular schedule builds habits
2. **Quality Over Quantity**: Better to do less, well
3. **Listen to Feedback**: Your audience knows what they want
4. **Experiment**: Try new formats and topics
5. **Collaborate**: Cross-promote with other creators

### Community Building

1. **Be Authentic**: Share your real self
2. **Respond Promptly**: Acknowledge your supporters
3. **Create Exclusivity**: Make members feel special
4. **Host Events**: Virtual meetups, Q&As
5. **Recognize Supporters**: Shoutouts, special perks

### Marketing Your Space

1. **Social Media**: Tease exclusive content
2. **Email List**: Regular updates to subscribers
3. **Free Samples**: Preview content publicly
4. **Referral Program**: Reward members who share
5. **SEO Optimization**: Descriptive titles and tags

## Troubleshooting

### Common Issues

**Stream Won't Start**
- Check browser permissions
- Test internet speed
- Try different browser
- Clear cache/cookies

**Payment Issues**
- Verify Stripe account
- Check bank details
- Review declined payments
- Contact support

**Low Engagement**
- Survey your audience
- Adjust content strategy
- Improve promotion
- Consider pricing

## Support

Need help? We're here for you:

- **Documentation**: [docs.backstagepass.app](https://docs.backstagepass.app)
- **Email**: creators@backstagepass.app
- **Discord**: [Join Creator Community](https://discord.gg/backstagepass)
- **Office Hours**: Tuesdays 2-3pm EST

---

Ready to grow your creator business? Let's get started! 🚀