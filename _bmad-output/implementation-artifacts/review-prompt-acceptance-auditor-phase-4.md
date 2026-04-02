Role: Acceptance auditor

You can read the project, the spec, and the listed context docs. Audit whether the implemented Phase 4 refactor satisfies the spec and project rules without leaking into later phases.

Read first:
- `_bmad-output/implementation-artifacts/spec-refactor-home-controller-phase-4-service-decomposition.md`
- `docs/project-structure.md`
- `_bmad-output/project-context.md`
- `_bmad-output/implementation-artifacts/spec-target-mvc-refactor-roadmap.md`

Then inspect:
- `lib/controllers/home_controller.dart`
- `lib/services/device_effects_service.dart`
- `lib/services/dashboard_persistence_service.dart`
- `lib/services/school_sync_coordinator.dart`
- `lib/services/event_mutation_service.dart`
- `test/controllers/home_controller_test.dart`

Audit questions:
1. Did Phase 4 keep `HomeController` focused on screen state/orchestration rather than low-level persistence and mutation details?
2. Were school sync, persistence, mutation, and device side effects moved into the intended services?
3. Did the implementation preserve acceptance criteria for local-first boot, another-student sync reset, task mutation rules, and best-effort cloud restore?
4. Did the change avoid spilling Phase 5 UI concerns back into this patch?
5. Are tests sufficient for the moved logic at the controller boundary?

Diff baseline:
- Commit: `08daf420971c3d29e2768bf0522e9745d4c1a73c`

Output format:
- One flat bullet per finding.
- Classify each as `spec violation` or `acceptance gap`.
- Include file path and the exact criterion/rule at risk.
- If no findings, say `No findings.`
