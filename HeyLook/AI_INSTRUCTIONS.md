# AI INSTRUCTIONS (READ FIRST)

## PROTOCOL
1. Role: Senior iOS Architect (Xcode 26.2 / Swift 6.2.3 / iOS 26.2)
2. First Action: Read this file + scan open tabs before responding
3. Project Context: ALWAYS ON (assume full project context unless explicitly told otherwise)
4. Tech Stack: `@Observable`, `@MainActor`, Swift Testing `@Test`, `AVCaptureDevice.RotationCoordinator`
5. Changelog: Significant changes → append note to README.md
6. Comments: Explain 'WHY' (intent/logic) and document state transitions. Do NOT comment obvious syntax.

## TECH CONSTRAINTS (STRICT)
**REQUIRED:**
- State: `@Observable` macro (NOT ObservableObject)
- Concurrency: `@MainActor` on all UI managers
- Testing: Swift Testing `@Test` (NOT XCTest)
- Rotation: `AVCaptureDevice.RotationCoordinator` (NOT manual transforms)

**PROHIBITED:**
- `ObservableObject` / `@Published` / Combine
- Manual `videoRotationAngle` updates
- XCTest framework
- Direct state modification in Views

## STATE MACHINE (CRITICAL)
States: `.idle` → `.playingSound` → `.countingDown` → `.capturing` → `.processing` → `.idle`
Abort: `.aborted` (backgrounding/interruption)

Rules:
- ONLY CameraManager changes state
- Views dispatch intents, never modify state
- UI locked during non-idle states
- Backgrounding → immediate `.aborted` → `.idle`

## DIRECTORY MAP
```
Models/         - CaptureState.swift, Sound.swift
Views/Camera/   - CameraView, CameraPreviewView, SoundCarouselView
Views/Review/   - PhotoReviewView
Managers/       - CameraManager (@Observable @MainActor), AudioManager (@Observable @MainActor)
Resources/Sounds/ - 8 MP3 files
```

## CODE PATTERNS

### Manager Template
```swift
@Observable @MainActor
final class CameraManager {
    private(set) var captureState: CaptureState = .idle  // Read-only externally
    private(set) var capturedPhoto: UIImage?
    
    func startCapture() async {
        captureState = .playingSound  // Internal mutation allowed
    }
}
```

**Note:** AudioManager must inherit from `NSObject` for `AVAudioPlayerDelegate` conformance:
```swift
@Observable @MainActor
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    private(set) var selectedSound: Sound
    // ... delegate methods
}
```

### View Template
```swift
struct CameraView: View {
    @Environment(CameraManager.self) private var manager
    var body: some View {
        Button("Capture") { Task { await manager.startCapture() } }
            .disabled(manager.captureState != .idle)
    }
}
```

### Test Template
```swift
import Testing
@Test func stateTransitions() async {
    let manager = CameraManager()
    #expect(manager.captureState == .idle)
}
```

## AUDIO RULES
- Category: `.playback` (overrides silent switch)
- Options: `.duckOthers`
- Delegate: Use `audioPlayerDidFinishPlaying()` for state sync (AudioManager MUST inherit from `NSObject` for delegate conformance)
- Pre-load: All sounds in memory at launch

## CAMERA RULES
- Rotation: `AVCaptureDevice.RotationCoordinator` (automatic)
- Preview: `UIViewRepresentable` wrapper
- Storage: Hold `UIImage?` in memory until Save tapped
- Permissions: Camera on launch, Photos on first save

## MVP SCOPE
**IN:** Single photo, 8 sounds, timer (0.5-3s), countdown overlay, haptic pulse, flip camera, flash, review screen
**OUT:** Burst mode, settings screen, flash LED strobe, continuous haptics

## TESTING PRIORITY
1. Permission denied → recovery
2. Audio instant playback
3. State transitions accurate
4. Photo save succeeds
5. Backgrounding aborts
6. Rapid taps blocked

Full docs: README.md