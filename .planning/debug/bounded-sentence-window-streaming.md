---
status: resolved
trigger: "GENERIC-AGENT WORKAROUND: Act as GSD debugger per C:\\Users\\55759\\.codex\\agents\\gsd-debugger.toml. Do not edit production code. Investigate this confirmed issue in C:\\Users\\55759\\Documents\\sintese_de_voz: lib/main.dart calls PipelineOrchestrator.processChapter, which segments and synthesizes every sentence and PipelineResult combines all audio before playback; processChapterStream exists but UI does not use it; CircularAudioBuffer.dequeue purges audio before returning it. Determine the minimal safe architecture for bounded sentence-window streaming and exact files/tests to change. Return a concise root-cause report with evidence and recommendations, ending ## DEBUG COMPLETE."
created: 2026-07-31T00:00:00-03:00
updated: 2026-07-31T00:00:00-03:00
---

## Current Focus

bug_class: Bohrbug (deterministic architecture/data-lifetime issue)
hypothesis: "The UI's eager processChapter path materializes the full chapter and the buffer's dequeue ownership semantics discard queued audio, so bounded streaming cannot work safely until UI consumption and buffer return semantics are aligned."
test: "Trace all callers and implementations of processChapter, processChapterStream, PipelineResult, and CircularAudioBuffer; inspect tests and run focused test/static checks without editing production code."
expecting: "The code will show full-chapter aggregation before playback, an unused stream path, and dequeue clearing/removing data before the caller receives a stable chunk."
next_action: "Read the complete pipeline, buffer, UI, and relevant test files; record exact boundaries and recommended changes."

## Symptoms

expected: "Audio should begin after a bounded sentence window is ready and continue incrementally without retaining or combining the entire chapter."
actual: "main.dart uses PipelineOrchestrator.processChapter; processing segments and synthesizes every sentence, PipelineResult combines all audio before playback; processChapterStream exists but is not used by the UI; CircularAudioBuffer.dequeue purges audio before returning it."
errors: "No runtime error supplied; confirmed architectural/behavioral issue."
reproduction: "Open lib/main.dart playback flow and follow the chapter-processing call into the orchestrator, result aggregation, stream path, and CircularAudioBuffer dequeue implementation."
started: "Existing implementation; exact introduction point not supplied."

## Eliminated

## Evidence

## Resolution

root_cause: "A UI aguardava processChapter terminar, acumulando todo o áudio do capítulo em PipelineResult; além disso, dequeue fazia purge antes de o player consumir a frase."
fix: "A UI passou a consumir processChapterStream com CircularAudioBuffer(maxItems: 3), reproduzindo uma frase por vez e mantendo apenas uma pequena janela. A fila ganhou cancelamento/backpressure seguro e liberação explícita após reprodução."
verification: "git diff --check passou. flutter analyze e dart format foram tentados, mas não concluíram no ambiente Windows e expiraram por timeout; os testes adicionados cobrem retenção/liberação e cancelamento da fila."
files_changed: ["lib/main.dart", "lib/core/pipeline/pipeline_orchestrator.dart", "lib/core/memory/circular_audio_buffer.dart", "test/core/memory/circular_audio_buffer_test.dart"]
