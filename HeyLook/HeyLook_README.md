# HeyLook - iOS Camera App

**Version:** 1.6 (Architecture Consolidation)  
**Last Updated:** December 22, 2025  
**Xcode:** 26.2  
**Swift:** 6.2.3  
**Target:** iOS 26.2  
**Minimum Deployment:** iOS 15.0

---

> 👨‍💻 **FOR AI ASSISTANTS & DEVELOPERS:** STRICT architectural rules, code patterns, and prohibited frameworks are defined in `AI_INSTRUCTIONS.md`. **Always read `AI_INSTRUCTIONS.md` first.**

---

## Project Overview
HeyLook is an iOS camera application designed to help parents and photographers capture better moments with children by playing attention-grabbing sounds before taking photos. The app combines intuitive camera controls with a sound library to elicit natural reactions and smiles from young subjects.

**Status:** Design & Planning Phase  
**Target Platform:** iOS (Xcode/Swift)  
**App Store Name:** HeyLook (subject to availability check)

---

## Core Concept
The app plays pre-recorded sounds (animal noises, silly sounds, etc.) to capture children's attention, followed by a configurable delay, then captures the photo. This timing sequence helps photographers get genuine reactions and engagement from young subjects.

---

## Feature Set

### MVP (Minimum Viable Product)

#### Main Camera Interface
- **Viewfinder:** Full-screen camera preview
- **Sound Carousel:** Horizontal swipeable carousel with 8 pre-loaded sounds
  - Visual indicator shows currently selected sound
  - Tap to preview sound before capture
- **Timer Wheel:** Vertical scrollable picker (0.5s - 3.0s in 0.5s increments)
  - Sets delay between sound playback and photo capture
- **Visual Countdown Toggle:** On/Off for attention-grabbing countdown
  - Screen overlay flashes/blinks every 0.5s (works for both front and rear camera)
- **Camera Controls:**
  - Front/rear camera flip button
  - Flash control (auto/on/off)
- **Capture Button:** Large, prominent button to initiate sequence

#### Capture Sequence Flow
1. User presses capture button
2. **State transition:** `.idle` → `.playingSound`
3. Selected sound plays (from pre-loaded buffer)
4. **State transition:** `.playingSound` → `.countingDown`
5. Visual countdown begins (if enabled) - screen overlay flashes
6. **Single haptic feedback** at start of countdown (photographer tactile awareness)
7. Countdown timer elapses
8. **State transition:** `.countingDown` → `.capturing`
9. Shutter sound plays
10. **Single photo captured**
11. **State transition:** `.capturing` → `.processing`
12. UI shows busy state (prevent double-capture)
13. **State transition:** `.processing` → `.idle`
14. Review screen appears

**State Machine Enforcement:**
- Sound selection carousel disabled during states: `.playingSound`, `.countingDown`, `.capturing`, `.processing`
- Timer wheel locked during active capture sequence
- Capture button disabled until state returns to `.idle`
- **Abort handling:** Interruptions (backgrounding, lock screen) transition to `.aborted` → `.idle` with cleanup

#### Review Screen
**Single Photo Mode (MVP):**
- Display captured photo
- "Save" button → requests Photos permission (if first time) → saves to Photos library
- "Retake" button → returns to camera

### Post-MVP Features
- **Settings Screen** (UIKit or SwiftUI - decide later)
  - Appearance toggle (Light/Dark/System)
  - Language selection
  - Favorite sounds management
  - Permissions status display
- **Burst Mode (3 photos):**
  - Rapid 3-shot capture
  - Review gallery with "Save All" / "Discard" options
  - Optional: Individual photo selection with checkboxes
- **Advanced Visual Countdown:**
  - Rear camera flash strobe (requires additional flash API work)
- **Enhanced Haptics:**
  - Continuous pulses every 0.5s during countdown (vs. single pulse at start)
- Custom sound uploads
- Expanded sound library with categories
- Filters and effects (premium feature)
- Extended burst modes (5, 10 shots)
- Timer presets/favorites
- Sound volume control independent of device
- Multi-language support
- In-app sound previews in settings
- Analytics (most-used sounds, capture success rate)

---

## Technical Architecture

### Frameworks Required
- **SwiftUI:** User interface (primary framework for MVP)
  - Modern, declarative UI perfect for our state-driven camera app
  - UIViewRepresentable wrapper for AVFoundation camera preview
  - Native components for carousel, timer wheel, toggles
- **AVFoundation:** Camera capture, video preview, audio playback
  - AVCaptureSession and all camera I/O remain imperative (not SwiftUI)
  - Managed inside CameraManager and AudioManager classes
  - **AVCaptureDevice.RotationCoordinator:** Standard iOS 26 API for handling device rotation (replaces manual layer transforms)
- **Photos/PhotoKit:** Save images to photo library
- **AVAudioSession:** Audio playback management (Category: `.playback` to override silent switch)
- **CoreHaptics:** Haptic feedback during capture sequence
- **Observation Framework:** Swift 6 native state management using `@Observable` macro (replaces ObservableObject/@Published)

### Key Components

#### 1. Camera Manager (@Observable, @MainActor)
- **Swift 6 Concurrency:** `@MainActor` isolated for strict concurrency compliance
- **State Management:** Uses `@Observable` macro for SwiftUI reactivity (no @Published needed)
- Manages AVCaptureSession
- Handles front/rear camera switching
- Controls flash settings (only enabled when hardware supports it)
- Captures single photos (burst mode deferred to post-MVP)
- Provides live preview feed via AVCaptureVideoPreviewLayer
- **Rotation Handling:** Uses `AVCaptureDevice.RotationCoordinator` (iOS 26 standard) for automatic device rotation handling
- **Photo Storage Strategy:**
  - Holds captured photo as `private(set) var capturedPhoto: UIImage?` in memory (read-only externally, writable internally)
  - Does NOT save to Photos library until user confirms via "Save" button
  - Keeps camera roll clean of rejected/retaken shots
- **State Machine Management:**
  - `private(set) var captureState: CaptureState` for SwiftUI reactivity (read-only externally, writable internally)
  - States: `.idle`, `.playingSound`, `.countingDown`, `.capturing`, `.processing`, `.aborted`
  - `.aborted` provides clean exit path for interruptions (backgrounding, lock screen, permission denial)
  - **Interruption Handling (MVP):** Any interruption during `.playingSound` or `.countingDown` aborts immediately → `.aborted` → `.idle`. User must retake. No pause/resume logic in MVP.
  - Prevents illegal state transitions (e.g., changing sound during countdown)
  - All state transitions on main actor
- **MVP Capture:** Single photo per trigger
- **Post-MVP:** Burst mode with sequential capture (3 photos)

#### 2. Audio Manager (@Observable, @MainActor, NSObject)
- **Swift 6 Concurrency:** `@MainActor` isolated for strict concurrency compliance
- **State Management:** Uses `@Observable` macro for SwiftUI reactivity
- **Delegate Conformance:** Must inherit from `NSObject` for `AVAudioPlayerDelegate` (Objective-C protocol requirement)
- Loads bundled sound files **into memory buffers** (pre-load on app launch to eliminate lag)
- `private(set) var selectedSound: Sound` for SwiftUI binding (read-only externally)
- Plays selected sound on demand
- Plays preview sounds
- Plays shutter sound on capture
- Manages audio session configuration
- **AVAudioSession Strategy:**
  - **Category:** `.playback` (overrides physical silent switch - critical for app functionality)
  - **Mode:** `.default`
  - **Options:** `.duckOthers` (lowers other audio like podcasts/music during sound playback, restores after)
- **Audio-State Sync:**
  - Use `AVAudioPlayerDelegate` to trigger state transitions
  - Transition to `.countingDown` only inside `audioPlayerDidFinishPlaying(_:successfully:)` callback
  - Ensures child hears full sound before countdown begins (no gaps or clips)
- **Volume Management:**
  - Monitor system volume level
  - Optional "Volume Boost" prompt if device volume < 50% (UX consideration)
  - Consider haptic feedback as backup attention-getter if volume is muted

#### 3. Timer Controller
- Manages configurable delay (0.5s - 3.0s)
- Triggers photo capture after delay
- Coordinates visual countdown if enabled

#### 4. Visual Countdown Handler
- **MVP:** Screen overlay flash/blink (works for both front and rear camera)
- Flashes every 0.5s during countdown
- Simple, universal implementation
- **Post-MVP:** Rear camera flash LED strobe (requires additional Flash API complexity)

#### 6. Haptic Feedback Manager
- **MVP:** Single haptic pulse at start of countdown
- Provides tactile feedback to photographer
- **Post-MVP:** Continuous pulses every 0.5s during countdown (may be distracting, needs user testing)

#### 7. Photo Storage Manager
- **Requests Photos library permissions on first save attempt** (not on app launch - improves trust and approval rates)
- Saves single photo to library (burst mode deferred to post-MVP)
- Handles success/error states
- Provides user feedback on save status

#### 8. UI Components (SwiftUI Views)
- **CameraView:** Main camera interface (root view)
- **CameraPreviewView:** UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
  - **Rotation:** Uses `AVCaptureDevice.RotationCoordinator` (iOS 26 standard API) - no manual `updateUIView` rotation handling needed
  - Automatic device rotation support via system API
- **SoundCarouselView:** Horizontal ScrollView with sound selection
  - Use `scrollTargetBehavior(.viewAligned)` for snappy feel (iOS 17+) or custom snap logic
- **TimerWheelView:** Picker for delay selection (0.5s - 3.0s)
- **CaptureButton:** Custom button view with state-aware styling
  - Uses `.disabled(captureState != .idle)` to prevent double-taps/spam
- **Camera control views:** Toggle for countdown, buttons for flip/flash
  - **Flash control:** Only supported when active camera provides flash; UI disables gracefully for unsupported cameras (e.g., front camera on older devices)
- **PhotoReviewView:** Single photo review with Save/Retake buttons
  - Photo held in observable property as `UIImage` or `Data` (not saved to library until user taps "Save")
  - Keeps camera roll clean of rejected shots
- **Visual Countdown Overlay:** ZStack overlay on camera view
  - Toggle state boolean with `withAnimation(.easeInOut(duration: 0.25).repeatForever())` for flash effect
- **Post-MVP:** Burst mode toggle, burst photo gallery with selection

### Permissions Required
- **Camera:** Required for photo capture (NSCameraUsageDescription)
  - Requested on app launch (core functionality depends on it)
- **Photos:** Required to save images to library (NSPhotoLibraryAddUsageDescription)
  - **Requested only on first save attempt** (not on launch - improves trust and approval rates)
- **Note:** Microphone permission is NOT required for playing sounds through speakers
- **Privacy Manifest:** Must include `PrivacyInfo.xcprivacy` file for App Store compliance (2024/2025 requirement)
  - Declare Photo Library access reason
  - Declare File Timestamp API usage (if applicable)

### Data Storage
- **Bundled Sounds:** 8 audio files (MP3/WAV) included in app bundle
- **User Preferences:** UserDefaults for settings (theme, selected sound, timer value, toggles)
- No cloud storage or user accounts for MVP

---

## Project Structure (Xcode)

```
HeyLook/
├── AI_INSTRUCTIONS.md (AI assistant rules - READ FIRST)
├── README.md (this file)
├── App/
│   ├── HeyLookApp.swift (SwiftUI App entry point)
│   ├── Info.plist
│   └── PrivacyInfo.xcprivacy
├── Models/
│   ├── Sound.swift
│   ├── CaptureSettings.swift
│   ├── PhotoCapture.swift
│   └── CaptureState.swift (State Machine enum: .idle, .playingSound, .countingDown, .capturing, .processing, .aborted)
├── Views/
│   ├── Camera/ (SwiftUI)
│   │   ├── CameraView.swift (main camera screen)
│   │   ├── CameraPreviewView.swift (UIViewRepresentable wrapper)
│   │   ├── SoundCarouselView.swift
│   │   ├── TimerWheelView.swift
│   │   └── CaptureButton.swift
│   └── Review/ (SwiftUI)
│       └── PhotoReviewView.swift
├── Managers/ (@Observable, @MainActor classes)
│   ├── CameraManager.swift (includes State Machine, uses RotationCoordinator)
│   ├── AudioManager.swift (includes buffer management, inherits NSObject)
│   ├── TimerController.swift
│   ├── VisualCountdownHandler.swift
│   ├── HapticFeedbackManager.swift
│   └── PhotoStorageManager.swift
├── Resources/
│   ├── Sounds/
│   │   ├── sound_01.mp3
│   │   ├── sound_02.mp3
│   │   ├── ... (8 total)
│   │   └── shutter.mp3
│   └── Assets.xcassets
└── Utilities/
    ├── Extensions/
    └── Constants.swift
```

---

## Development Phases

### Phase 1: Project Setup ✅
- [x] Define app concept and features
- [x] Create technical specification
- [x] Initialize Xcode project (Xcode 26.2, Swift 6.2.3, iOS 26.2)
- [x] Configure bundle ID and signing
- [x] Set up project structure
- [x] Create `PrivacyInfo.xcprivacy` manifest
- [x] Configure Info.plist permission descriptions
- [x] Add README to project
- [ ] Set up Swift Testing framework (using @Test macro, not XCTest)

### Phase 2: Camera Core
- [ ] Implement CameraManager with AVFoundation (@Observable, @MainActor)
- [ ] Integrate AVCaptureDevice.RotationCoordinator for rotation handling
- [ ] Build camera preview view (UIViewRepresentable)
- [ ] Add front/rear camera switching
- [ ] Add flash control
- [ ] Test single photo capture

### Phase 3: Audio System
- [ ] Source/create 8 sounds for MVP (ensure sounds are precisely trimmed - no silence at start/end)
- [ ] Implement AudioManager (@Observable, @MainActor)
- [ ] Implement AVAudioPlayerDelegate for state sync
- [ ] Add sound preview functionality
- [ ] Add shutter sound playback
- [ ] Test audio playback reliability and ducking behavior

### Phase 4: Timer & Countdown
- [ ] Build timer wheel UI
- [ ] Implement TimerController
- [ ] Create VisualCountdownHandler
- [ ] Test countdown timing accuracy
- [ ] Sync visual feedback with delays

### Phase 5: UI Components
- [ ] Build sound carousel interface
- [ ] Create toggle switches (burst, countdown)
- [ ] Design and implement capture button
- [ ] Add camera control buttons
- [ ] Implement settings screen structure

### Phase 6: Capture Flow Integration
- [ ] Wire up capture sequence (sound → delay → photo)
- [ ] Implement single photo capture mode
- [ ] Test full capture flow end-to-end
- [ ] Handle state transitions and cleanup

### Phase 6.5: Internal Demo Milestone 🎯
**Goal:** End-to-end proof of concept on physical device
- [ ] Complete capture sequence works: sound → delay → photo → save
- [ ] Camera permissions handled
- [ ] Audio plays reliably (overrides silent switch)
- [ ] Photos save to library successfully
- [ ] State machine prevents illegal UI interactions
- **Deliverable:** Showable prototype for feedback/testing

### Phase 7: Review & Save
- [ ] Build single photo review screen
- [ ] Implement "Save" button with Photos permission request
- [ ] Implement "Retake" button
- [ ] Handle permissions and errors
- [ ] Test save functionality thoroughly

### Phase 8: Polish & Optimization
- [ ] App icon and launch screen
- [ ] User preference persistence (selected sound, timer value, countdown toggle)
- [ ] Error messaging and user feedback
- [ ] Performance optimization
- [ ] Memory management review
- [ ] Bug fixes and edge cases
- [ ] User experience refinement
- [ ] Test on multiple devices

### Phase 9: App Store Prep
- [ ] Verify "HeyLook" name availability
- [ ] Create app store screenshots
- [ ] Write app description
- [ ] Privacy policy
- [ ] Prepare for submission

---

## Current Status

**Last Updated:** December 22, 2025  
**Current Phase:** Phase 1 - Project Setup  
**Next Steps:** 
1. Initialize Xcode project with SwiftUI
2. Configure basic project settings and structure
3. Set up version control (Git)
4. Create mock CameraManager for simulator testing (camera doesn't work in simulator)

---

## Design Notes

### UX Principles
- **Simplicity:** Camera interface should feel familiar (inspired by Snapchat/native iOS camera)
- **Speed:** Minimize taps between opening app and taking photo
- **Clarity:** Visual feedback for all actions (sound selection, timer, toggles)
- **Forgiveness:** Easy retake option if photo isn't perfect

### Sound Selection Strategy
Initial 8 sounds should cover variety:
- 2-3 animal sounds (duck, cow, dog)
- 2-3 silly/funny sounds (boing, whistle, pop)
- 2-3 musical/attention sounds (xylophone, bell, chime)

### Visual Design
- Clean, minimal interface
- Large touch targets for easy use
- High contrast for outdoor visibility
- Dark mode support for low-light situations

---

## Technical Considerations

### Performance
- Camera preview must be smooth (60fps target)
- Sound playback must be instantaneous (pre-loaded buffers)
- Photo capture should be responsive with minimal delay
- Photo processing should not block UI
- Memory management during repeated captures

### Edge Cases to Handle
- Low storage space on device
- Denied permissions (camera/photos)
- Sound playback failure (corrupted audio file)
- Camera initialization failure
- **App backgrounding during capture:**
  - **MVP Strategy:** Abort immediately → `.aborted` → `.idle`. User must retake.
  - Save current state for logging/debugging
  - Cancel active timers and audio
- **Interruptions during countdown:**
  - Phone call: Abort to `.idle`, user retries when ready
  - Notification: Abort if audio session interrupted
  - Control Center: Abort, user retries
  - Lock screen: Abort sequence immediately
  - **No pause/resume logic in MVP** - keeps behavior deterministic and testable
- **System volume at 0%:** Warn user that sounds won't be audible
- **Visual countdown:** Screen overlay works on both front and rear camera (no hardware dependency in MVP)
- **Memory pressure during capture:** Monitor and handle gracefully
- **Rapid repeated capture button taps:** Button uses `.disabled(captureState != .idle)` to prevent double-capture or stuck states

### Testing Priorities
1. Capture sequence timing accuracy
2. Burst mode reliability
3. Photo save success rate
4. Audio playback consistency
5. Permission handling
6. Memory management during repeated captures

---

## Critical Technical Decisions

### 1. SwiftUI + Swift 6 Strict Concurrency Architecture
**Decision:** SwiftUI for entire MVP with Swift 6.2.3 strict concurrency
- **All UI:** SwiftUI views with declarative syntax
- **Camera Preview:** UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
- **State Management:** Observation framework with `@Observable` macro (Swift 6 native, replaces ObservableObject/@Published)
- **Concurrency:** `@MainActor` isolation for all managers touching UI state
- **Reactive Updates:** `async/await` patterns, no legacy Combine publishers

**Intent-Based Architecture:**
- Views dispatch user intents (captureTapped, soundSelected, timerChanged, flipCameraTapped)
- Managers handle side effects and update observable state
- No direct manager function calls from Views - keeps Views "dumb" and state machine enforceable

**Rationale:** Swift 6 strict concurrency prevents data races at compile time. Observation framework is more performant and has cleaner syntax than Combine. Developer has SwiftUI experience. Faster development with live preview. State machine maps perfectly to SwiftUI's reactive patterns.

### 2. Audio Session Configuration
**Decision:** `AVAudioSession.Category.playback`
- **Overrides silent switch:** Critical for app functionality (sounds must play to capture attention)
- **Allows mixing:** Won't interrupt user's music
- **Pre-load audio buffers:** Eliminate playback lag

**Rationale:** Core app value depends on sounds playing reliably. Parents expect animal sounds to work even if phone is on silent.

### 3. Simplified MVP Scope
**Decision:** Defer burst mode and settings screen to post-MVP
- **MVP:** Single photo capture only
- **MVP:** No settings screen (not required for core functionality testing)
- **Post-MVP:** 3-shot burst with "Save All" / "Discard" review
- **Post-MVP:** Settings screen (appearance, language, favorites)

**Rationale:** Fastest path to testable prototype. Settings screen adds no value to core capture flow testing. Burst mode adds complexity without validating core concept. Demo milestone focuses on: sound → delay → photo → save.

### 4. Device Rotation Handling
**Decision:** Use `AVCaptureDevice.RotationCoordinator` (iOS 26 standard API)
- **Automatic rotation:** System handles preview layer rotation
- **No manual transforms:** Eliminates manual `videoRotationAngle` updates in `updateUIView`
- **Simpler code:** Reduces edge cases and rotation bugs

**Rationale:** iOS 26 provides native rotation coordination. Manual rotation handling was error-prone and required continuous monitoring. Modern API is more reliable and requires less code.

### 5. State Machine Architecture
**Decision:** Explicit state management in `CameraManager` with `@Observable`
- **States:** `.idle`, `.playingSound`, `.countingDown`, `.capturing`, `.processing`, `.aborted`
- **`.aborted` state:** Clean exit path for interruptions (backgrounding, lock screen, permission denial)
- **Enforcement:** Disable UI elements during active states (automatically reactive via Observation)
- **Concurrency:** All state transitions on main actor (@MainActor isolation)

**Rationale:** Prevents race conditions and illegal states (e.g., user changing settings mid-capture). `.aborted` state provides explicit cleanup path and helps with debugging/logging. Makes state flow testable. Swift 6 concurrency enforcement prevents data races at compile time.

### 6. Testing Framework
**Decision:** Swift Testing (using `@Test` macro)
- **Modern syntax:** Cleaner than XCTest
- **Better error messages:** More readable test failures
- **Swift-first:** Native Swift patterns, not Objective-C legacy
- **Async support:** First-class `async/await` support

**Rationale:** Swift Testing is Apple's modern testing framework announced at WWDC 2024 (Xcode 16+). Better integration with Swift 6. XCTest is legacy.

### 7. Deferred Features (Post-Demo)
**Decision:** Simplify MVP implementation
- **Visual Countdown:** Screen overlay only (defer flash LED strobe - complex Flash APIs)
- **Haptic Feedback:** Single pulse at countdown start (defer continuous pulses - may be distracting)
- **Burst Review:** "Save All" / "Discard" (defer individual photo checkboxes - adds UI complexity)

**Rationale:** Each deferred feature adds edge cases and testing burden. Screen overlay works universally. Single haptic is sufficient for MVP feedback. Get to demo milestone faster.

### 8. Permissions Strategy
**Decision:** Strategic permission request timing
- **Camera:** Request on launch (core functionality requires it)
- **Photos:** Request only on first save attempt (not on launch)
- Must include `PrivacyInfo.xcprivacy` for App Store compliance

**Rationale:** Requesting Photos permission only when needed improves user trust and approval rates. Users understand context when they're about to save. Camera permission upfront is justified since app is useless without it.

---

## MVP Testing Priorities

### Must-Test for Demo Milestone
These 6 items are **critical** for MVP validation. Everything else can be logged as "known limitations."

1. **Camera permission denied → recovery**
   - User denies permission: Show clear message with Settings deeplink
   - User grants permission: Camera initializes successfully
   - Test: Toggle permission in Settings and reopen app

2. **Audio plays instantly**
   - Sound plays immediately on capture button press
   - No perceivable lag between button tap and sound
   - Audio overrides silent switch (AVAudioSession `.playback` category)
   - Audio ducks background audio (podcasts/music) during playback
   - Test: Measure time from button press to sound playback

3. **Capture flow timing feels consistent and predictable**
   - Timer delays feel accurate to user (~0.1s perceived accuracy target)
   - Visual countdown syncs with timer
   - State transitions happen in correct order
   - Audio finishes completely before countdown starts (no clipping)
   - Test: Record capture sequence, verify timing feels natural

4. **Save succeeds**
   - Photos permission request appears on first save
   - Photo saves to library successfully
   - Saved photo matches captured photo quality
   - Test: Save 10+ photos, verify all appear in Photos app

5. **App background during countdown**
   - App backgrounds mid-countdown: Timer cancels, aborts to `.idle`
   - App returns to foreground: UI is responsive, ready for new capture
   - No crashes or frozen states
   - Test: Background app at each state in capture sequence

6. **Rapid repeated capture button taps**
   - Capture button disables instantly on tap (`.disabled(captureState != .idle)`)
   - No double-capture
   - No stuck `.processing` state
   - Test: Spam capture button rapidly, verify single capture only

### Can Be Deferred (Log as Known Limitations)
- Timer precision beyond ±50ms
- Low memory handling during capture
- Rapid repeated captures (spam prevention)
- Audio playback failure recovery
- Exact behavior on very old devices (iPhone 8 and earlier)
- Dark mode support
- Localization
- Accessibility features

---

## Notes & Decisions

- **Working Name:** HeyLook (subject to App Store availability check)
- **MVP Focus:** Sound → Delay → Photo → Save (core capture flow must be rock-solid)
- **Demo Milestone:** Phase 6.5 - working prototype on physical device
- **Deferred to Post-MVP:**
  - Burst mode (3-shot capture)
  - Settings screen (appearance, language, favorites)
  - Flash LED strobe for visual countdown
  - Continuous haptic pulses
  - Individual photo selection in burst review
- **Timer Range:** 0.5s - 3.0s in 0.5s increments (covers most use cases)
- **Sound Count:** 8 bundled sounds (sufficient variety for MVP)
- **Architecture:** SwiftUI for entire MVP (UIViewRepresentable for camera preview)
- **Audio Strategy:** AVAudioSession `.playback` category (overrides silent switch)
- **State Management:** 6-state machine (`.idle`, `.playingSound`, `.countingDown`, `.capturing`, `.processing`, `.aborted`) with @Published properties
- **Permission Timing:** Camera on launch, Photos on first save
- **Haptic Feedback:** Single pulse at countdown start (photographer tactile awareness)

---

## Questions to Resolve (MVP)
- [ ] Final 8 sound files - where to source/create? **Ensure sounds are precisely trimmed (no silence at start/end)**
- [ ] App icon design direction
- [ ] Exact wording for permission requests (Camera + Photos)
- [ ] Default settings for MVP:
  - Timer: 1.0s default?
  - Visual countdown: ON or OFF by default?
- [ ] Volume warning threshold (< 50%? < 30%?)
- [ ] Error messaging strategy (alerts vs. toast vs. inline)
- [ ] **Device Testing:** Paid Apple Developer account available? (Required for physical device camera testing)
- [ ] **Simulator Strategy:** Build mock CameraManager that returns static image for UI development without device

## Questions to Resolve (Post-MVP)
- [ ] Burst count (3, 5, 10 photos?)
- [ ] Settings screen framework (UIKit or SwiftUI?)
- [ ] Premium features strategy (filters, effects, expanded sound library)
- [ ] Monetization model (free with IAP? paid upfront? subscription?)
- [ ] Haptic pattern refinement (continuous pulses vs. single pulse)
- [ ] Flash LED strobe implementation complexity

---

## Contact & Collaboration
This README should be updated as the project evolves. When starting new chat sessions, reference this document to maintain context and continuity.

---

## Changelog

**Version:** 1.6 (Architecture Consolidation)  
**Last Modified:** December 22, 2025

**Changes in v1.6:**
- **Refactored AI rules:** Moved all AI assistant instructions to dedicated `AI_INSTRUCTIONS.md` file
- **Simplified README:** Now focuses on project overview, architecture, and roadmap
- **Added prominent pointer:** AI assistants directed to read `AI_INSTRUCTIONS.md` first
- **Updated project structure:** Includes `AI_INSTRUCTIONS.md` at root level

**Changes in v1.5:**
- **Migrated to Swift 6.2.3 with strict concurrency:** All code now uses Swift 6 concurrency model
- **Observation Framework:** Replaced ObservableObject/@Published with @Observable macro (Swift 6 native state management)
- **@MainActor Isolation:** All managers (CameraManager, AudioManager) are now @MainActor isolated for compile-time data race safety
- **AVCaptureDevice.RotationCoordinator:** Using iOS 26 standard API for camera rotation (removed manual rotation handling)
- **Swift Testing Framework:** Migrated from XCTest to Swift Testing using @Test macro
- **async/await patterns:** Removed legacy Combine publishers, all async operations use structured concurrency
- **Updated target:** iOS 26.2 SDK, Xcode 26.2
- **Added AI Agent Guidelines:** Comprehensive instructions for AI assistants to follow project patterns and avoid legacy code
- **Intent-based architecture clarified:** Views dispatch intents, managers update observable state

**Changes in v1.4:**
- **Clarified SwiftUI/AVFoundation separation:** Views are declarative (SwiftUI), camera/audio are imperative (AVFoundation in Managers)
- **Intent-based architecture:** Views dispatch intents, Managers handle side effects
- **Audio improvements:**
  - Changed to `.duckOthers` option (lowers background audio during attention sounds)
  - Added `AVAudioPlayerDelegate` requirement for state sync (no gaps between sound and countdown)
- **Camera preview rotation handling:** Documented manual rotation handling in UIViewRepresentable
- **Flash control refinement:** Only enabled when hardware supports it, gracefully disabled otherwise
- **Photo storage strategy:** Hold in memory (`@Published var capturedPhoto`), only save on user confirmation
- **Interruption strategy clarified:** MVP aborts immediately (no pause/resume), deterministic behavior
- **Testing priorities updated:**
  - Changed timer accuracy from "±50ms" to "feels consistent (~0.1s perceived)"
  - Added 6th test: Rapid button taps (prevent double-capture)
  - Added audio ducking test
- **UI Component details:** ScrollView snap behavior, capture button disable logic, overlay animation
- **Edge cases refined:** Removed flash/burst references, clarified abort-only strategy
- **Performance section:** Removed burst references (MVP is single capture)
- **Questions added:** Sound file trimming, simulator mock strategy, device testing requirements
- **Fixed:** "Next Steps" now says SwiftUI (not UIKit)

**Changes in v1.3:**
- **Switched to SwiftUI:** Changed from UIKit to SwiftUI for entire MVP
- **Rationale:** Developer has SwiftUI experience; faster development with declarative UI
- **Architecture updates:**
  - Managers are now ObservableObject classes with @Published properties
  - Views are SwiftUI views (except CameraPreviewView using UIViewRepresentable)
  - State management uses Combine framework
  - Project structure updated (HeyLookApp.swift instead of AppDelegate/SceneDelegate)
- **Removed:** LaunchScreen.storyboard from structure
- **Added:** Combine framework to dependencies

**Changes in v1.2:**
- **Simplified MVP scope:** Deferred burst mode, settings screen, and complex features to post-MVP
- **Phase 6.5 added:** Internal demo milestone (sound → delay → photo → save on physical device)
- **UIKit-only for MVP:** Removed SwiftUI hybrid approach, may revisit for Settings post-MVP
- **Added `.aborted` state:** Clean exit path for interruptions and edge cases
- **Simplified features:**
  - Visual countdown: Screen overlay only (deferred flash LED strobe)
  - Haptic feedback: Single pulse at start (deferred continuous pulses)
  - Burst review: Deferred entirely to post-MVP
- **Renamed `Controllers/` → `Managers/`:** Avoid UIKit MVC confusion
- **Photos permission timing:** Request on first save, not launch
- **Added "MVP Testing Priorities" section:** 5 must-test items for demo milestone
- **Consolidated development phases:** Removed Phase 10, merged testing into Phase 8

**Changes in v1.1:**
- Decided on UIKit/SwiftUI hybrid architecture
- Specified AVAudioSession `.playback` category strategy
- Added explicit State Machine architecture to Camera Manager
- Clarified permissions (removed microphone requirement)
- Added PrivacyInfo.xcprivacy requirement
- Documented burst mode implementation approach (sequential)
- Added haptic feedback to capture sequence
- Expanded edge case handling (interruptions, volume warnings)
- Created "Critical Technical Decisions" section
