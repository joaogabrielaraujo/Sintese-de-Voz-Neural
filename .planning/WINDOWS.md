---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 3
total_count: 5
last_updated: 2026-08-01T19:29:25.701Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 14 | deviation | lib/main.dart |  | Corrected progress completion and duplicate EPUB re-import resume behavior | fixed |  | 2026-08-01T19:27:11.677Z | 2026-08-01T19:29:24.052Z |
| 2 | 14 | deviation | lib/core/document/saved_book_repository.dart |  | Validated persisted book identifiers before filesystem path construction | fixed |  | 2026-08-01T19:27:12.692Z | 2026-08-01T19:29:24.838Z |
| 3 | 14 | deviation | lib/ui/widgets/audio_player_control_bar.dart |  | Replaced fixed compact controls with responsive wrapping to prevent overflow | fixed |  | 2026-08-01T19:27:14.041Z | 2026-08-01T19:29:25.701Z |
| 4 | 14 | unrun-verify |  |  | Full Flutter analyze produced no output for more than two minutes and was terminated; changed-file analysis passed | open |  | 2026-08-01T19:27:14.722Z |  |
| 5 | 14 | unrun-verify |  |  | Full Flutter test produced no output for more than 93 seconds and was terminated; 14 targeted tests passed | open |  | 2026-08-01T19:27:15.418Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "14",
    "file": "lib/main.dart",
    "line": null,
    "description": "Corrected progress completion and duplicate EPUB re-import resume behavior",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-01T19:27:11.677Z",
    "resolved_at": "2026-08-01T19:29:24.052Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "14",
    "file": "lib/core/document/saved_book_repository.dart",
    "line": null,
    "description": "Validated persisted book identifiers before filesystem path construction",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-01T19:27:12.692Z",
    "resolved_at": "2026-08-01T19:29:24.838Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "14",
    "file": "lib/ui/widgets/audio_player_control_bar.dart",
    "line": null,
    "description": "Replaced fixed compact controls with responsive wrapping to prevent overflow",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-01T19:27:14.041Z",
    "resolved_at": "2026-08-01T19:29:25.701Z"
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "14",
    "file": "",
    "line": null,
    "description": "Full Flutter analyze produced no output for more than two minutes and was terminated; changed-file analysis passed",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-01T19:27:14.722Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "unrun-verify",
    "phase": "14",
    "file": "",
    "line": null,
    "description": "Full Flutter test produced no output for more than 93 seconds and was terminated; 14 targeted tests passed",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-01T19:27:15.418Z",
    "resolved_at": null
  }
]
````
