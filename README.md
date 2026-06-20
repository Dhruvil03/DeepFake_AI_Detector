# DeepFake AI Detector (iOS)

SwiftUI port of **Proofy**, the Android deepfake/content-authenticity app, rebuilt around a
self-hosted OpenAI-compatible inference endpoint instead of Google's hosted Gemini API.

## Visual theme

The Android app's icon is just a plain white "P" mark on transparent — no real color data to
pull from it. The actual Proofy brand palette lives in the project's browser-extension popup
(`popup.css`), so that's what this app's theme is built from: a dark "neon glass" look.

| Role | Color | Hex |
|---|---|---|
| Background | near-black | `#020202` |
| Primary accent (image/text actions, "authentic" verdict) | neon green | `#00FF88` |
| Secondary accent (video/audio actions) | neon blue | `#00D1FF` |
| Danger ("synthetic" verdict) | alert red | `#FF3366` |
| Inconclusive verdict *(added — not in the original palette, which only defines green/blue/red)* | neon amber | `#FFD23F` |
| Surfaces | translucent white glass | `rgba(255,255,255,0.03)` + soft border |

Defined in `Sources/Shared/Theme.swift` (`ProofyPalette`, `NeonButtonStyle`,
`NeonSecondaryButtonStyle`, `.glassCard()`, `.proofyBackground()`) and applied across every
screen — dashboard cards, buttons, result cards, history rows, and forms.

## What's included

- **Image Analysis** — picks a photo, sends it as `image_url` (base64 data URI), parses a
  structured JSON verdict.
- **Video Analysis** — picks a video, sends the whole clip as `video_url` (base64 data URI),
  same pattern as the original working curl example. `MediaEncoder.extractFrames` is also
  included if you'd rather sample frames client-side instead of uploading the full file (see
  "Video frame sampling" below).
- **Text Verification** — fact-checks a pasted claim.
- **Audio Analysis** — record in-app or import a file, sent as `audio_url`.
- **History** — local JSON-file history of past analyses, nothing leaves the device except the
  request to your configured endpoint.
- **Settings** — endpoint URL / model name / max tokens are editable at runtime, defaulting to:
  - endpoint: `http://130.191.48.8:8001/v1/chat/completions`
  - model: `google/gemma-4-26B-A4B-it`

## Not included / intentionally different from the Android app

iOS doesn't allow third-party floating overlays or global hardware-key interception, so:
- **Quick Capture / Overlay Service** → not built here. The cleanest iOS equivalent is a **Share
  Extension** ("Verify with DeepFake AI Detector" in the system share sheet) or a **Home Screen
  widget** / **Control Center control** (iOS 18+). Happy to scaffold either as a next step.
- **Volume-key trigger (Accessibility Service)** → no equivalent API on iOS. Closest UX is
  **Back Tap** (Settings → Accessibility → Touch → Back Tap → assign a Shortcut).
- **Source Finder** (reverse image search) → left out because it needs a separate
  reverse-image-search backend; let me know if you have one and I'll wire it in.

## Build instructions

This project ships as **source files + an XcodeGen spec**, not a binary `.xcodeproj`, since
hand-editing Xcode project files is fragile.

### Option A — XcodeGen (recommended)
```bash
brew install xcodegen
cd DeepFakeAIDetector
xcodegen generate
open DeepFakeAIDetector.xcodeproj
```
Then in Xcode: select the **DeepFakeAIDetector** target → **Signing & Capabilities** → pick
your team → Run on a simulator or device.

### Option B — Manual Xcode project
1. Xcode → File → New → Project → iOS → App. Name it `DeepFakeAIDetector`, interface: SwiftUI,
   no Core Data.
2. Delete the default `ContentView.swift` and app-entry file Xcode generated.
3. Drag the entire `Sources/` folder from this download into the project navigator
   ("Copy items if needed" checked).
4. Replace the auto-generated `Info.plist` entries with the ones in this repo's `Info.plist`
   (camera/mic/photo-library usage strings + the ATS exception for your endpoint's IP).
5. Build & run.

## Before you ship this

1. **Secure the endpoint.** It's currently plain HTTP with no auth. Before App Store
   submission, put it behind TLS (App Transport Security will otherwise require an exception,
   which Apple sometimes pushes back on at review) and add an API key/header your app sends.
2. **Validate detection accuracy.** A general multimodal model isn't a calibrated forensic
   detector for any of these modalities — build a small eval set of known real/fake samples per
   modality before trusting confidence scores in front of users. The prompts here are written to
   make the model conservative ("inconclusive" over guessing), but that's a mitigation, not a fix.
3. **Video frame sampling (optional alternative to full-video upload).** If base64-encoding
   entire video files is too slow/large, swap `VideoAnalysisViewModel` to call
   `MediaEncoder.extractFrames(from:maxFrames:)` and send N `image_url` blocks instead of one
   `video_url` block — same JSON contract, cheaper requests.
4. **Privacy disclosure.** Since media is sent to a third-party-controlled server for analysis,
   add a clear in-app disclosure of what's transmitted and whether anything is retained
   server-side.
5. **App icon.** No icon asset is included — you'll need to design one (the source Proofy icon
   is just a plain white mark with no real branding to reuse).

## Project structure

```
Sources/
├── App/DeepFakeAIDetectorApp.swift  # entry point
├── Core/
│   ├── Networking/                  # InferenceClient, request/response models, MediaEncoder
│   ├── Models/AnalysisResult.swift  # verdict/confidence parsing (incl. JSON-from-prose extraction)
│   ├── Settings/AppSettings.swift   # endpoint/model config, persisted in UserDefaults
│   ├── Persistence/HistoryStore.swift
│   └── Prompts/PromptTemplates.swift
├── Features/
│   ├── Dashboard/
│   ├── ImageAnalysis/
│   ├── VideoAnalysis/
│   ├── TextVerification/
│   ├── AudioAnalysis/
│   ├── Result/ResultCard.swift      # shared verdict/confidence UI
│   ├── History/
│   └── Settings/
└── Shared/
    ├── Theme.swift                  # ProofyPalette, neon button styles, glass card modifier
    └── SharedViews.swift
```
