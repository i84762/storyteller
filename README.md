# StoryTeller 📖🎙️

A Flutter **PDF Voice Assistant** with a tiered subscription model and AI model selector.

## Features

- 📄 **PDF Extraction** — Load any PDF and have it read aloud
- 🎙️ **Voice Interaction** — Speak to navigate, control playback, or ask questions
- 🧠 **Intent Detection** — Every voice input is classified as Navigate / Control / Inquire
- 🔀 **Four AI Tiers** — Switch between Free, Premium, BYOK, and On-Device

## AI Tier System

| Tier | Backend | Cost |
|------|---------|------|
| **Free** | Gemini Free (rate-limited) | Free · 10 req/day |
| **Premium** | Developer-managed Gemini Pro | £1.99/month |
| **BYOK** | Your own Gemini or OpenAI key | 20p/month platform fee |
| **On-Device** | Gemini Nano (on-device, private) | £2.99/month |

## Tech Stack

- **State Management** — Provider
- **TTS / STT** — `flutter_tts` · `speech_to_text`
- **PDF** — `syncfusion_flutter_pdf`
- **AI** — `google_generative_ai` · OpenAI REST API · On-device stub (google_ai_edge)
- **IAP** — `in_app_purchase`
- **Secure Storage** — `flutter_secure_storage`

## Architecture

```
lib/
├── main.dart
├── app.dart
├── models/          # SubscriptionTier, AISource, IntentResult, TokenUsage
├── services/        # ModelManager, GeminiService, OpenAIService, PdfService,
│                    # TtsService, SttService, IAPService, UsageTracker, OnDeviceService
├── providers/       # ModelProvider, ReaderProvider, SubscriptionProvider
├── screens/         # Home, Reader, Settings, Subscription
├── widgets/         # VoiceInputButton, ModelSelectorCard, UsageIndicator
└── utils/           # Constants, IntentParser
```

## Getting Started

1. Add your developer Gemini API key to `lib/utils/constants.dart`
2. Configure IAP product IDs in the same file
3. Run `flutter pub get && flutter run`

> **Note:** The On-Device tier requires the `google_ai_edge` package once it is stable.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
