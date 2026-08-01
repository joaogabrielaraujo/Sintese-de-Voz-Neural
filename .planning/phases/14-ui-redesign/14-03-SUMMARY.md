---
phase: 14-ui-redesign
plan: 03
subsystem: audio-streaming
tags: [flutter, offline-tts, audioplayers, epub, streaming, cancellation]
requires:
  - phase: 14-01
    provides: responsive EPUB reader, offline synthesis pipeline, and native audio callbacks
provides:
  - Generation-owned stream lifecycle that rejects stale iterator, queue, and audio continuations
  - One-item look-ahead that prepares the next synthesized sentence while the current sentence plays
  - Serialized stop, close, chapter-change, and engine-switch transitions
affects: [14-04, 14-05, 14-07, android-uat, windows-uat]
actuals:
  tokens: 24000
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [generation-owned async state, serialized stream transitions, one-item audio look-ahead]
key-files:
  created:
    - test/ui/stream_cancellation_test.dart
  modified:
    - lib/main.dart
key-decisions:
  - "Prepare at most one next SentenceAudioItem while the current item is audible; never add a fixed delay to disguise pipeline latency."
  - "Treat residual source-switch delay from a single audioplayers instance as a native-player limitation to measure in device UAT, not as synthesis latency."
patterns-established:
  - "Every asynchronous streaming continuation revalidates generation, iterator, queue, mounted state, and active item before mutation."
  - "Cancellation increments generation before iterator cancellation, player stop, and queue disposal."
requirements-completed: []
coverage:
  - id: D1
    description: "Prepared next sentence removes fresh iterator/synthesis waiting from the normal completion handoff"
    verification:
      - kind: automated_ui
        ref: "test/ui/stream_cancellation_test.dart#prepared next item is consumed without a second iterator gate"
        status: pass
    human_judgment: true
    rationale: "Widget tests prove controller ordering; perceived continuity still depends on the Android/Windows native audio backend."
  - id: D2
    description: "Stale audio cannot load or play after stream replacement"
    verification:
      - kind: automated_ui
        ref: "test/ui/stream_cancellation_test.dart#gated stale load cannot produce a play call after replacement"
        status: pass
    human_judgment: false
duration: 0min
completed: 2026-08-01
status: complete
---

# Phase 14 Plan 03: Stream Handoff Summary

**The reader now prepares one next offline-TTS sentence during current playback, so normal sentence completion no longer waits for a new stream advance or synthesis result.**

## Accomplishments

- Added generation-owned stream transitions for start, stop, chapter change, reader close, and engine switch.
- Added one-item look-ahead: after playback begins, the controller advances the bounded iterator once and retains only the prepared next sentence.
- Completion consumes the prepared item before requesting additional stream work; cancellation clears and releases it safely.
- Added deterministic regressions for stale audio after replacement and for prepared-next consumption without a second iterator gate.

## Validation

- `flutter test --no-pub test/ui/stream_cancellation_test.dart` — passed (2/2).
- `flutter analyze --no-pub lib/main.dart test/ui/stream_cancellation_test.dart` — no issues.

## Limitation and UAT

The remaining audible gap, if any, is now limited to native `audioplayers` source switching for successive in-memory WAV sources. A single player does not guarantee sample-accurate gapless playback. Plan 14-07 requires listening to at least 20 consecutive sentences on Android and Windows, recording any residual mechanical stall and its observed duration. A persistent native gap is follow-up work for a dual-player preloaded handoff or continuous audio timeline; it must not be masked with arbitrary delays.

## Commit

- `cf5acc7` — `feat(14-03): prepare next sentence during playback`

