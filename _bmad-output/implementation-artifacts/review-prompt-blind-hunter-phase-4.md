Role: Blind hunter

You are reviewing a refactor diff only. Do not ask for more context and do not assume intent beyond the diff itself.

Goal:
- Find concrete bugs, regressions, unsafe behavior changes, and missing defensive handling introduced by the Phase 4 HomeController decomposition.
- Prioritize findings by severity.
- Ignore style nits unless they hide a real defect.

Diff baseline:
- Commit: `08daf420971c3d29e2768bf0522e9745d4c1a73c`

Focus files:
- `lib/controllers/home_controller.dart`
- `lib/services/device_effects_service.dart`
- `lib/services/dashboard_persistence_service.dart`
- `lib/services/school_sync_coordinator.dart`
- `lib/services/event_mutation_service.dart`
- `test/controllers/home_controller_test.dart`
- `docs/project-structure.md`

Also note these related untracked files now exist:
- `lib/services/device_effects_service.dart`
- `lib/services/dashboard_persistence_service.dart`
- `lib/services/school_sync_coordinator.dart`
- `lib/services/event_mutation_service.dart`
- `_bmad-output/implementation-artifacts/spec-refactor-home-controller-phase-4-service-decomposition.md`

How to inspect:
1. Read the diff from baseline for the focus files.
2. Review only what changed or was added.
3. Return findings only.

Output format:
- One flat bullet per finding.
- Include severity (`high`, `medium`, `low`).
- Include file path and the exact behavior risk.
- If no findings, say `No findings.`
