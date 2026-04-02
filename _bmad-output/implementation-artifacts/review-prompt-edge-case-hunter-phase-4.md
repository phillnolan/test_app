Role: Edge case hunter

You can read the project. Review the Phase 4 HomeController decomposition with emphasis on branching paths, fallback behavior, null/empty states, auth timing, local-first persistence, and attachment/cloud edge cases.

Goal:
- Report only real edge cases that are unhandled or behaviorally risky.
- Focus on the new boundaries between `HomeController` and the new services.

Relevant files:
- `lib/controllers/home_controller.dart`
- `lib/services/device_effects_service.dart`
- `lib/services/dashboard_persistence_service.dart`
- `lib/services/school_sync_coordinator.dart`
- `lib/services/event_mutation_service.dart`
- `lib/models/local_cache_payload.dart`
- `lib/models/home_action_result.dart`
- `lib/models/student_event.dart`
- `test/controllers/home_controller_test.dart`

Context to respect:
- Local-first boot must survive cloud failure.
- Only `personalTask` may be deleted.
- Syncing another student must clear old `personalEvents`.
- Device effects are best-effort.
- View/UI concerns like scroll controller ownership are not part of this phase.

Suggested inspection path:
1. Read the focus files.
2. Compare against baseline commit `08daf420971c3d29e2768bf0522e9745d4c1a73c`.
3. Look for edge cases around:
- empty cache
- remote payload older/newer/null
- cloud sync failures after local save
- attachment local/base64/remote fallback
- auth event timing during initialize
- event ordering after mutation

Output format:
- One flat bullet per finding.
- Include severity, file path, trigger scenario, and user-visible impact.
- If no findings, say `No findings.`
