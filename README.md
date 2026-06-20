# DeepFake AI Detector (iOS)

A SwiftUI iOS app for AI-assisted content authenticity verification — analyzes images, video,
text, and audio for signs of AI generation or manipulation, using a configurable
OpenAI-compatible inference endpoint.

## What's included

- **Image Analysis** — picks a photo, sends it as `image_url` (base64 data URI), parses a
  structured JSON verdict.
- **Video Analysis** — picks a video, sends the whole clip as `video_url` (base64 data URI).
  `MediaEncoder.extractFrames` is also available if you'd rather sample frames client-side and
  send a sequence of `image_url` blocks instead — useful for endpoints/models that don't accept
  `video_url` directly (see "Video frame sampling" below).
- **Text Verification** — fact-checks a pasted claim.
- **Audio Analysis** — record in-app or import a file. This is a **two-step pipeline**, not a
  direct audio upload: the clip is first transcribed via a Whisper-compatible
  `/audio/transcriptions` endpoint (`TranscriptionClient.swift`), then the transcript text is
  run through the same JSON-verdict analysis as Text Verification. This means it evaluates
  *what was said*, not *how it sounds* — it cannot detect synthetic-voice artifacts (prosody,
  spectral signal, cloning tells) directly. The transcript is shown in the UI so this is visible
  to the user, not hidden behind a confidence score.
- **History** — local JSON-file history of past analyses, nothing leaves the device except the
  requests to your configured endpoints.
- **Settings** — editable at runtime, no rebuild needed:
  - **Endpoint URL** — main inference endpoint for image/video/text and the audio transcript
    analysis step
  - **Model name**
  - **API key** *(optional)* — sent as `Authorization: Bearer <key>` if non-empty; leave blank
    for an unauthenticated self-hosted endpoint
  - **Max tokens**

  Audio transcription uses a **separate, independent endpoint and model**
  (`transcriptionEndpointURL` / `transcriptionModelName` in `AppSettings.swift`), not exposed in
  the Settings UI by design — edit those defaults directly in code if you need to point
  transcription somewhere other than the default. This split exists because a single model
  often can't do both general chat/vision *and* audio transcription well, so audio can be routed
  to a different provider than everything else without affecting the rest of the app.

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

Re-run `xcodegen generate` any time you add or remove source files (it won't pick up new files
automatically otherwise).

### Option B — Manual Xcode project
1. Xcode → File → New → Project → iOS → App. Name it `DeepFakeAIDetector`, interface: SwiftUI,
   no Core Data.
2. Delete the default `ContentView.swift` and app-entry file Xcode generated.
3. Drag the entire `Sources/` folder from this download into the project navigator
   ("Copy items if needed" checked).
4. Replace the auto-generated `Info.plist` entries with the ones in this repo's `Info.plist`.
5. Build & run.

## Before you ship this

1. **Secure the endpoint.** An unauthenticated plain-HTTP endpoint needs an `Info.plist` ATS
   exception (`NSAllowsArbitraryLoads`) — fine for development, but App Store review may push
   back on it. Before shipping, put the endpoint behind TLS and require the API key field.
2. **Validate detection accuracy.** This uses a general-purpose multimodal model, not one
   trained specifically on labeled real/fake datasets — build a labeled eval set of known
   real/fake samples per modality before trusting confidence scores in front of users.
3. **Video frame sampling (optional alternative to full-video upload).** If base64-encoding
   entire video files is too slow/large, or your model/endpoint doesn't accept `video_url`,
   swap `VideoAnalysisViewModel` to call `MediaEncoder.extractFrames(from:maxFrames:)` and send
   N `image_url` blocks instead — same JSON contract, different request shape.
4. **Privacy disclosure.** Media is sent to your configured endpoint(s) for analysis — add a
   clear in-app disclosure of what's transmitted and whether anything is retained server-side.
5. **API key storage.** Currently stored in `UserDefaults` for development convenience. Move to
   Keychain before sharing this build with anyone else, since this can be a real billable
   credential.
6. **App icon.** No icon asset is included — you'll need to design one.

## Project structure

```
Sources/
├── App/DeepFakeAIDetectorApp.swift  # entry point
├── Core/
│   ├── Networking/
│   │   ├── InferenceClient.swift        # main chat completions client
│   │   ├── TranscriptionClient.swift    # audio transcription client (separate endpoint)
│   │   ├── ChatCompletionModels.swift   # request/response types, InferenceConfig
│   │   └── MediaEncoder.swift           # base64 data URIs, video frame extraction
│   ├── Models/AnalysisResult.swift  # verdict/confidence parsing (incl. JSON-from-prose extraction)
│   ├── Settings/AppSettings.swift   # endpoint/model/API key config, persisted in UserDefaults
│   ├── Persistence/HistoryStore.swift
│   └── Prompts/PromptTemplates.swift
├── Features/
│   ├── Dashboard/
│   ├── ImageAnalysis/
│   ├── VideoAnalysis/
│   ├── TextVerification/
│   ├── AudioAnalysis/               # transcribe-then-analyze pipeline + transcript display
│   ├── Result/ResultCard.swift      # shared verdict/confidence UI
│   ├── History/
│   └── Settings/
└── Shared/
    ├── Theme.swift                  # color palette, neon button styles, glass card modifier
    └── SharedViews.swift
```

## Results
<img width="473" height="962" alt="image" src="https://github.com/user-attachments/assets/1a66f2c6-e7d5-4d7f-be77-c2f0c3ea2670" />

## Image Analysis
<img width="473" height="962" alt="image" src="https://github.com/user-attachments/assets/a08fd73c-ed54-4584-a693-99ead5d8bdc1" />

## Video Analysis
<img width="473" height="962" alt="image" src="https://github.com/user-attachments/assets/fc18253d-fdba-4f5e-8e2f-9a025633457f" />

## Text Verification
<img width="473" height="962" alt="image" src="https://github.com/user-attachments/assets/13f455f4-defc-416d-bb03-678bc6c04f38" />




