# 🧪 Golden Path Test Plan - Creator & Viewer Flows

**Date:** 2025-10-03  
**Status:** Ready for Testing  
**Prerequisites:** All 10 commits merged, slugs unique, permissions granted

---

## 🎨 **Creator/Streamer Flow**

### Phase 1: Experience Management ✅ VERIFIED

**1.1 Create Experience**
- [x] Sign in as creator
- [x] Navigate to Space dashboard
- [x] Click "Add New Experience"  
- [x] Fill form (Name, Type, Description, Price)
- [x] Submit form
- [x] **Expected:** Redirect to experience show page with success message
- [x] **Actual:** Working! (Experience ID 16 created)

**1.2 Edit Experience**
- [ ] Click "Edit" on experience
- [ ] Modify name/description
- [ ] Change price
- [ ] Submit
- [ ] **Expected:** Updates save, redirect to show page

**1.3 View Experience Details**
- [ ] Navigate to experience show page
- [ ] Verify all details display correctly
- [ ] Check if streams section shows
- [ ] Verify public URL is correct

---

### Phase 2: Stream Management (NEEDS TESTING)

**2.1 Create Stream**
- [ ] From experience page, click "Add New Stream"
- [ ] Fill stream details (Title, Description, Scheduled time)
- [ ] Submit form
- [ ] **Expected:** Stream created, shows in upcoming streams list

**2.2 Start Streaming (Go Live)**
- [ ] Click "Go Live" or "Start Stream"
- [ ] Verify LiveKit connection initializes
- [ ] Check if video preview shows
- [ ] Test audio/video permissions
- [ ] **Expected:** Stream status changes to "live"

**2.3 Stream Controls**
- [ ] Test mute/unmute
- [ ] Test camera on/off
- [ ] Test screen share
- [ ] Verify chat panel loads
- [ ] **Expected:** All controls functional

**2.4 End Stream**
- [ ] Click "End Stream"
- [ ] Confirm dialog
- [ ] **Expected:** Stream status changes to "ended"

---

### Phase 3: Monetization (NEEDS TESTING)

**3.1 Create Access Pass**
- [ ] Navigate to Space dashboard
- [ ] Click "Add New Access Pass"
- [ ] Set name, description, price
- [ ] Link to experiences
- [ ] Submit
- [ ] **Expected:** Access pass created, shows on space page

**3.2 Configure Pricing**
- [ ] Edit experience
- [ ] Set different price tiers
- [ ] Test free vs paid options
- [ ] **Expected:** Pricing displays on public pages

---

### Phase 4: Analytics & Management (FUTURE)

**4.1 View Analytics**
- [ ] Navigate to space/experience analytics
- [ ] Check viewer counts
- [ ] Check revenue data
- [ ] **Expected:** Dashboard shows accurate metrics

---

## 👁️ **Viewer Flow**

### Phase 1: Discovery ✅ VERIFIED

**1.1 Browse Marketplace**
- [x] Visit `/explore`
- [x] See list of spaces with cards
- [x] Verify CSS renders correctly
- [x] Check search/filter works
- [x] **Actual:** Perfect! Purple gradients, fully styled

**1.2 View Space Page**
- [x] Click space card
- [x] Navigate to `/your-team` (public space page)
- [x] See experience listings
- [x] Verify pricing displays
- [x] **Actual:** Working! Clickable experience cards

**1.3 View Experience Page**
- [x] Click experience card
- [x] Navigate to `/your-team/console-test-stream`
- [x] See experience details
- [x] Check stream schedule
- [x] **Actual:** Working! No nil crashes

---

### Phase 2: Access & Purchase (NEEDS TESTING)

**2.1 Free Experience Access**
- [ ] As unauthenticated user, click free experience
- [ ] **Expected:** Prompt to sign in
- [ ] Sign in
- [ ] **Expected:** Redirect back to experience

**2.2 Paid Experience - Purchase Flow- [ ] Click paid experience
- [ ] See pricing information
- [ ] Click "Purchase" or "Get Access"
- [ ] Fill payment form (Stripe test mode)
- [ ] Complete purchase
- [ ] **Expected:** Access granted, can view content

**2.3 Purchase Verification**
- [ ] Check AccessGrant created in database
- [ ] Verify Billing::Purchase record
- [ ] Check user can access all experiences in pass
- [ ] **Expected:** Access persists across sessions

---

### Phase 3: Stream Viewing (CRITICAL - NEEDS TESTING)

**3.1 Join Live Stream**
- [ ] Navigate to live experience
- [ ] Click "Join Stream" or auto-join
- [ ] **Expected:** LiveKit connects, video appears

**3.2 Video Player**
- [ ] Verify video plays smoothly
- [ ] Test volume controls
- [ ] Test fullscreen mode
- [ ] Check latency/quality
- [ ] **Expected:** Smooth playback, low