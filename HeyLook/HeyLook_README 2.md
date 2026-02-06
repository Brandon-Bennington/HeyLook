# HeyLook - iOS Camera App

**Version:** 2.0 (Current Implementation)  
**Last Updated:** February 6, 2026  
**Xcode:** 16+  
**Swift:** 6.2+  
**Target:** iOS 18.0+  

---

## Project Overview

HeyLook is an iOS camera application designed to help parents and photographers capture better moments with children by playing attention-grabbing sounds before taking photos. The app combines intuitive camera controls with a customizable sound library to elicit natural reactions and smiles from young subjects.

---

## Core Features

### Camera Interface

The app features a full-screen camera experience with:

#### Sound Selection
- **Customizable Favorites:** Users can select up to 5 favorite sounds from the settings
- **Sound Carousel:** Horizontal swipeable carousel displays user's favorite sounds
- **Visual Feedback:** Selected sound is highlighted with a white border and scale animation
- **Sound Preview:** Double-tap any sound to preview it before capture
- **Emoji Icons:** Each sound is represented by a fun emoji (🦆 for Duck, 🐮 for Cow, etc.)

#### Timer Control
- **Timer Wheel:** Vertical picker wheel to adjust delay between sound and photo capture
- **Range:** 0.5s to 3.0s in 0.5-second increments
- **Default:** 1.0s delay

#### Camera Controls
- **Flip Camera:** Switch between front and rear cameras
- **Flash Control:** Toggle flash on/off (when hardware supports it)
- **Settings Button:** Access settings to customize photo ratio and favorite sounds

#### Capture Sequence
1. User presses the capture button
2. Selected sound plays
3. Timer countdown begins with visual flash effect
4. Photo is captured automatically when timer completes
5. Review screen appears with captured photo

#### Photo Review
- **Swipe Down to Retake:** Intuitive gesture to dismiss and try again
- **Save Button:** Saves photo to Photos library (requests permission on first save)
- **Success Banner:** Confirmation when photo is saved successfully

### Settings Screen

#### Photo Ratio Selection
Users can choose from 4 aspect ratios:
- **3:4** - Portrait, Standard
- **4:3** - Landscape, Classic  
- **16:9** - Wide, Cinematic
- **1:1** - Square, Instagram

Each ratio includes a visual preview of the aspect ratio shape.

#### Favorite Sounds Management
- **Select Up to 5 Favorites:** Choose which sounds appear in the camera carousel
- **Drag to Reorder:** Long-press and drag sounds to change the order they appear in the camera view
- **Grid Selection:** All 8 available sounds displayed in a grid
- **Visual Feedback:** Selected sounds show blue background with checkmark
- **Sound Preview:** Double-tap any sound in the grid to preview it
- **Quick Remove:** Tap the X button on favorited sounds to remove them

### Available Sounds

The app includes 8 built-in attention sounds:
1. 🦆 **Duck**
2. 🐮 **Cow**
3. 🐶 **Dog**
4. 🌀 **Boing**
5. 😗 **Whistle**
6. 💥 **Pop**
7. 🔔 **Bell**
8. ✨ **Chime**

---

## Technical Architecture

### Frameworks Used

- **SwiftUI** - Modern, declarative UI framework for all views
- **AVFoundation** - Camera capture and audio playback
- **Photos/PhotoKit** - Saving images to photo library
- **Observation Framework** - Swift 6 native state management using `@Observable` macro

### Key Components

#### 1. CameraManager (@Observable, @MainActor)
- Manages AVCaptureSession for camera preview and photo capture
- Implements state machine for capture sequence
- Handles camera switching and flash control
- Coordinates with AudioManager for sound playback
- Manages photo capture and storage
- **States:** `.idle`, `.playingSound`, `.countingDown`, `.capturing`, `.processing`, `.aborted`

#### 2. AudioManager (@Observable, @MainActor)
- Pre-loads all sound files into memory for instant playback
- Manages sound selection and playback
- Configures AVAudioSession to override silent switch
- Provides sound preview functionality
- **Audio Category:** `.playback` with `.duckOthers` option (sounds play even on silent mode)

#### 3. SettingsManager (@Observable, @MainActor)
- Manages user preferences (photo ratio, favorite sounds)
- Persists settings to UserDefaults
- Provides default favorite sounds (first 5 sounds if not customized)
- Handles favorite sound reordering

#### 4. CameraView
- Main SwiftUI view containing the entire camera interface
- Integrates viewfinder, controls, sound carousel, and timer wheel
- Handles photo review presentation
- Manages visual countdown flash effect

#### 5. Supporting Views
- **CameraPreviewView:** UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
- **SoundCarouselView:** Horizontal scrollable sound selection
- **TimerWheelView:** Picker wheel for delay adjustment
- **CaptureButton:** Large, prominent button to trigger capture
- **SettingsView:** Full settings interface with photo ratio and sound customization

### State Management

The app uses Swift's modern Observation framework with the `@Observable` macro:
- No `@Published` properties needed
- Automatic UI updates when observable properties change
- `@MainActor` isolation ensures all UI updates happen on the main thread
- Strict concurrency compliance with Swift 6

### Permissions

#### Camera Permission
- **When Requested:** On app launch
- **Required:** Yes - core functionality depends on it
- **Usage Description:** "HeyLook needs camera access to take photos"

#### Photos Library Permission  
- **When Requested:** Only on first save attempt
- **Required:** No - user can take photos without saving
- **Usage Description:** "HeyLook needs Photos access to save your captured images"

---

## Project Structure

```
HeyLook/
├── HeyLookApp.swift              # App entry point, dependency injection
├── CameraView.swift              # Main camera interface
├── CameraPreviewView.swift       # AVFoundation camera preview wrapper
├── SoundCarouselView.swift       # Sound selection carousel
├── TimerWheelView.swift          # Timer delay picker
├── CaptureButton.swift           # Capture button component
├── FlipCameraButton.swift        # Camera flip button
├── SettingsButton.swift          # Settings button
├── SettingsView.swift            # Settings screen with photo ratio and favorites
├── CameraManager.swift           # Camera and capture logic
├── AudioManager.swift            # Audio playback management
├── SettingsManager.swift         # User preferences management
├── Sound.swift                   # Sound model and definitions
├── CaptureState.swift            # Capture sequence state machine
└── Resources/
    └── Sounds/
        ├── duck.mp3
        ├── cow.mp3
        ├── dog.mp3
        ├── boing.mp3
        ├── whistle.mp3
        ├── pop.mp3
        ├── bell.mp3
        ├── chime.mp3
        └── shutter.mp3
```

---

## User Experience Features

### Intuitive Gestures
- **Swipe Down on Photo Review:** Retake photo
- **Drag to Reorder Favorites:** Long-press and drag sounds in settings
- **Double-Tap for Preview:** Hear sounds before selecting them

### Visual Feedback
- **Flash Effect:** Screen flashes during countdown to help get subject's attention
- **Selected Sound Highlight:** White border and scale animation
- **Disabled State:** Controls gray out during capture sequence
- **Success Banner:** Confirmation when photo is saved

### Smart Defaults
- **Default Timer:** 1.0 second delay
- **Default Favorites:** First 5 sounds (Duck, Cow, Dog, Boing, Whistle)
- **Default Ratio:** 4:3 (Classic landscape)
- **Dark Mode:** App uses dark theme optimized for camera use

### Audio Design
- **Override Silent Switch:** Sounds always play (essential for app functionality)
- **Duck Other Audio:** Temporarily lowers music/podcast volume during sound playback
- **Pre-loaded Sounds:** Zero lag when playing sounds

---

## Development Status

### ✅ Completed Features

- [x] Full camera functionality with front/rear switching
- [x] Flash control
- [x] Sound carousel with emoji icons
- [x] Customizable timer wheel (0.5s - 3.0s)
- [x] State machine for capture sequence
- [x] Visual countdown flash effect
- [x] Photo review with swipe-to-retake
- [x] Save to Photos library with permission handling
- [x] Settings screen
- [x] Photo aspect ratio selection (3:4, 4:3, 16:9, 1:1)
- [x] Favorite sounds management (select up to 5)
- [x] Drag-to-reorder favorites
- [x] Sound preview functionality
- [x] Persistent user preferences
- [x] Success feedback on save

### 🚧 Known Limitations

- No burst mode (captures one photo at a time)
- No custom sound uploads
- No sound volume control independent of device
- No filters or effects
- No in-app sound library expansion
- English only (no localization)

### 💡 Future Enhancements

- **Burst Mode:** Capture 3-5 photos in quick succession
- **Custom Sounds:** Allow users to upload their own attention sounds
- **Sound Categories:** Organize sounds into groups (animals, silly, musical)
- **Volume Control:** Independent volume slider for app sounds
- **Filters:** Photo effects and color adjustments
- **Multi-language Support:** Localization for international users
- **Analytics:** Track most-used sounds and settings
- **iCloud Sync:** Sync preferences across devices
- **Widget:** Quick capture from home screen
- **Apple Watch Control:** Start capture from watch

---

## Testing Notes

### Critical Test Cases

1. **Camera Permission Flow**
   - Grant permission → Camera initializes
   - Deny permission → Error message with Settings link

2. **Sound Playback**
   - Sounds play instantly when capture triggered
   - Sounds override silent switch
   - Background audio ducks during playback

3. **Capture Sequence Timing**
   - Sound plays completely before countdown starts
   - Timer delay feels accurate
   - Visual flash syncs with countdown
   - Photo captures at correct moment

4. **Photo Review & Save**
   - Swipe down dismisses review
   - Photos permission requested on first save
   - Photos appear in Photos app after save
   - Success banner appears after save

5. **Settings Persistence**
   - Selected photo ratio persists across app launches
   - Favorite sounds and order persist
   - Timer value persists

6. **Edge Cases**
   - App backgrounding during capture aborts cleanly
   - Rapid button taps don't cause double-capture
   - Favorites list handles 0-5 sounds correctly
   - Reordering favorites updates carousel immediately

---

## Design Philosophy

### Simplicity First
- Minimal taps from launch to photo
- Clear, large touch targets
- Familiar camera interface patterns

### Child-Friendly
- Fun emoji representations
- Engaging sounds that capture attention
- Quick capture sequence keeps kids engaged

### Parent-Focused
- Easy one-handed operation
- Reliable sound playback (overrides silent mode)
- Quick retake option for imperfect shots
- Clean photo library (only saved photos go to library)

### Performance
- Instant sound playback (pre-loaded)
- Smooth camera preview (60fps target)
- Responsive UI with no lag
- Efficient memory usage

---

## Changelog

**Version 2.0** - February 6, 2026
- Updated README to reflect actual implementation
- Documented all current features accurately
- Removed outdated technical decisions and phases
- Added complete feature descriptions
- Documented user experience details
- Updated project structure to match codebase

**Version 1.6** - December 22, 2025
- Architecture consolidation
- Moved AI instructions to separate file

**Version 1.5** - December 22, 2025
- Migrated to Swift 6.2.3 with strict concurrency
- Observation Framework implementation
- AVCaptureDevice.RotationCoordinator integration

---

## Contact & Updates

This README reflects the current state of the HeyLook project as of February 6, 2026. For questions or contributions, reference this document and the codebase itself.
