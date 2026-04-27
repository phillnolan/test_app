---
name: dev
description: "Use when implementing a new Flutter feature end-to-end. This skill orchestrates the existing skills architecture-feature-first, riverpod, dart-3-updates, and effective-dart instead of redefining them."
---

# Dev Skill

This skill is the entry point for building a **new Flutter feature**.

It does **not** redefine architecture, state management, or coding-style rules.
Instead, it coordinates these already-existing skills and applies them in sequence:

1. `architecture-feature-first`
2. `riverpod`
3. `dart-3-updates`
4. `effective-dart`

---

## When to Use

Use this skill when:

- Creating a new feature under `lib/features/`
- Adding a new screen or user flow
- Wiring repositories, services, providers, and UI for a new feature
- Implementing a feature from empty scaffold to working code

Do **not** use this skill for:

- Tiny bug fixes
- Pure UI polish
- Firebase setup
- E2E tests
- Large legacy refactors across multiple unrelated areas

---

## Required Sub-Skills

When this skill is used, the agent must call and follow these existing skills:

- `architecture-feature-first`
- `riverpod`
- `dart-3-updates`
- `effective-dart`

Do not substitute alternatives unless the user explicitly asks.

---

## Execution Order

### 1. Apply `architecture-feature-first`
Use it first to:
- decide feature boundaries
- choose file/folder placement
- separate UI, data, and optional domain logic
- ensure repositories/services/state holders live in the correct layer

### 2. Apply `riverpod`
Use it next to:
- create providers/notifiers for the feature
- wire dependency injection
- manage async state, loading, and actions
- connect UI to state correctly with `ref.watch` / `ref.read`

### 3. Apply `dart-3-updates`
Use it while writing implementation code to:
- prefer modern Dart 3 constructs where they improve clarity
- use sealed classes, switch expressions, records, and patterns appropriately
- avoid old verbose branching when Dart 3 provides a clearer form

### 4. Apply `effective-dart`
Use it before finishing to:
- normalize naming
- ensure idiomatic Dart structure and style
- keep files focused and readable
- verify public APIs and general code quality

---

## Workflow

For every new feature, follow this sequence:

1. Identify the feature goal.
2. Use `architecture-feature-first` to define the feature structure.
3. Create the minimum working vertical slice.
4. Use `riverpod` to implement state and dependency wiring.
5. Use `dart-3-updates` while writing/refining the feature code.
6. Use `effective-dart` as the final quality pass.
7. Return only the files and code needed for the feature.

---

## Rules

- Prefer the smallest complete feature slice first.
- Do not introduce another state-management solution.
- Do not bypass the repository/data boundary.
- Do not apply Dart 3 features where they reduce readability.
- Do not refactor unrelated legacy code unless required for the feature.
- Follow existing project conventions unless they directly conflict with one of the required sub-skills.

---

## Output Expectation

A successful use of this skill should produce:

- a new feature implemented in the correct location
- Riverpod-based state wiring
- code written with appropriate Dart 3 features
- code cleaned up to Effective Dart standards
- no duplicated architectural guidance that already exists in the referenced skills
