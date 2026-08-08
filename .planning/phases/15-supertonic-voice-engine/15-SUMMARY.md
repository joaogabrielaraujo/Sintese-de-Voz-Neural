# Phase 15 Summary: Supertonic 3 & Piper VITS Engine Optimization

## Executed Work

1. **Sherpa-ONNX Upgrade:** Updated `sherpa_onnx` to version 1.13.x in `pubspec.yaml` with full backwards compatibility for Piper VITS.
2. **Supertonic 3 Integration:** Integrated optional `SupertonicOnnxEngine` into `CompositeTTSEngine` with automatic fallback chain (`Supertonic 3` -> `Piper VITS` -> `Sherpa CLI`).
3. **Threading & Isolate Offloading:**
   - Offloaded `SupertonicOnnxEngine` C++ FFI synthesis to a background `Isolate` (`Isolate.run`), completely eliminating UI thread freezing on Windows Desktop.
   - Configured `numThreads: 4` for multi-core CPU matrix acceleration.
4. **Prosody & Natural Pause Tuning:**
   - Fixed `TTSConfig.defaultPtBr()` parameters: `noiseScale` set to `0.85` (expressive pitch modulation), `lengthScale` set to `1.0` (natural cadence).
   - Added `trimSilence(padMs: 250)` to `AudioBuffer` to preserve a 250ms intentional human breathing pause between sentences.
   - Added punctuation-aware spacing in `PhoneticNormalizer` to enforce `espeak-ng` clause pauses for `,`, `;`, `:`, `?`, `!`.
5. **Scope & UI Speed Control:**
   - Restricted playback speed selector (`AudioPlayerControlBar`) to max `1.5x` when Supertonic 3 is active to preserve continuous gapless playback without buffer depletion.
   - Piper VITS retains speeds up to `2.0x` with ultra-fast RTF (~0.12).
6. **APK Readiness:**
   - Confirmed Piper VITS model (`pt_BR-faber-medium.onnx` ~63 MB) is bundled in assets for a lightweight ~75-85 MB release APK (`flutter build apk --release`).

## Empirical Results

- **Piper VITS (HiFi-GAN Faber):** RTF = **0.115 - 0.137** (Synthesis time ~550ms for 4.8s audio).
- **Supertonic 3 (int8 ONNX):** RTF = **0.61 - 0.64** with `numSteps = 6` (Synthesis time ~2.15s for 3.36s 2x audio).

## Test Suite Status

- **Unit & Integration Tests:** All 16/16 tests passing cleanly (`flutter test`).
