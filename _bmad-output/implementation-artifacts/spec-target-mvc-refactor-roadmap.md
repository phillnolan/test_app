---
title: 'Target MVC refactor roadmap'
type: 'refactor'
created: '2026-04-02T22:10:00+07:00'
status: 'proposed'
context:
  - 'docs/project-structure.md'
  - 'docs/mvc-refactor-notes.md'
  - '_bmad-output/project-context.md'
---

## Intent

**Problem:** Codebase hien tai da theo MVC thuc dung, nhung van con mot so vung chua "sach MVC" hoan toan. Mot so business logic van nam trong `views`, mot so presentation mapping van nam trong `services`, va `HomeController` dang om qua nhieu trach nhiem cung luc.

**Target State:** Dua codebase ve gan hon voi MVC chuan ma khong doi sang MVVM, BLoC, Riverpod, hay them application layer moi. View chi render va giu state form cuc bo. Controller giu state man hinh va dieu phoi use case. Service chi lam viec ky thuat hoac nghiep vu co the tai su dung. Model va utils chua du lieu typed, presenter, mapper, va ham thuan.

## Non-Goals

- Khong doi kien truc state management hien tai (`ChangeNotifier` + `ListenableBuilder`).
- Khong doi UX, copy, hay flow nguoi dung neu khong bat buoc.
- Khong refactor dong loat toan bo app trong mot dot.
- Khong tach lop chi de "du MVC" neu logic chua du lon.
- Khong nhan rong refactor vao Cloudflare Worker neu khong can thiet cho ranh gioi MVC cua Flutter app.

## Target Architecture

```text
views/
  - render UI
  - giu state form cuc bo
  - mo dialog/sheet/snackbar
  - gui input typed xuong controller

controllers/
  - giu state man hinh
  - dieu phoi flow
  - goi service/use case
  - tra ve presentation state hoac result typed

services/
  - xu ly ky thuat
  - xu ly nghiep vu tai su dung duoc
  - parse/integration/persistence/device sync
  - khong phu thuoc widget tree

models/ + utils/
  - model typed
  - DTO / result object
  - presenter / mapper
  - ham thuan
```

## Proposed New Files

- `lib/controllers/grades_controller.dart`
- `lib/models/local_cache_payload.dart`
- `lib/models/home_action_result.dart`
- `lib/models/weather_presentation.dart`
- `lib/services/school_sync_coordinator.dart`
- `lib/services/event_mutation_service.dart`
- `lib/services/dashboard_persistence_service.dart`
- `lib/services/device_effects_service.dart`
- `lib/services/attachment_import_service.dart`
- `lib/services/image_edit_service.dart`
- `lib/utils/grade_metrics.dart`
- `lib/utils/curriculum_presenter.dart`
- `lib/utils/weather_presenter.dart`

## Current-to-Target Mapping

### 1. Grades flow

**Current issues**
- `lib/views/grades/grades_page.dart` tu tinh GPA, total credits, va loc `gradesForGpa`.
- `lib/views/grades/widgets/goal_planner_section.dart` chua business logic day du cho GPA planner.
- `lib/views/grades/widgets/curriculum_subjects_section.dart` tu dedupe, group, va suy ra completion state trong view.

**Target split**
- Chuyen metric tinh diem sang `lib/utils/grade_metrics.dart`.
- Chuyen curriculum grouping/presentation sang `lib/utils/curriculum_presenter.dart`.
- Neu logic tab diem tiep tuc lon len, tao `lib/controllers/grades_controller.dart` de gom state va use case cho tab nay.

**Functions / logic to move**
- From `grades_page.dart`:
  - `gpaCountedCodes`
  - `gradesForGpa`
  - `totalCredits`
  - `gpa`
- From `goal_planner_section.dart`:
  - `_calculateGoalPlan`
  - `_buildRetakePool`
  - `_deriveGoalDefaults`
  - `_bestPassedGradesByCode`
  - `_dedupedCurriculum`
  - `_isPassingGrade`
  - `_GoalPlanResult`
  - `_GoalDefaults`
  - `_RetakeCandidate`
  - `_MarkBand`
- From `curriculum_subjects_section.dart`:
  - `_dedupedSubjects`
  - `_passedCodesFor`
  - `_bestGradesByCode`
  - `_groupSubjects`

### 2. Home controller

**Current issues**
- `lib/controllers/home_controller.dart` dang giu qua nhieu vai tro:
  - state man hinh
  - sync truong
  - local cache
  - cloud sync
  - task / note mutation
  - attachment flow
  - device side effects
  - UI concern lien quan scroll/day strip

**Target split**
- Giu `HomeController` lam screen controller.
- Tach use case / orchestration co the tai su dung sang service nho.
- Dua UI concern tro lai view.

**Functions / logic to move**
- To `lib/services/school_sync_coordinator.dart`:
  - `syncSchoolData`
  - `_payloadFromSnapshot`
- To `lib/services/event_mutation_service.dart`:
  - `addTask`
  - `editEvent`
  - `deletePersonalEvent`
  - `toggleDone`
  - `openAttachment`
  - `_uploadMissingAttachments`
- To `lib/services/dashboard_persistence_service.dart`:
  - `_loadLocalCache`
  - `_restoreAndSyncCloudState`
  - `_persistPayload`
  - `_syncPayloadToCloud`
  - `_shouldUseRemotePayload`
  - `_selectedDateForPayload`
- To `lib/services/device_effects_service.dart`:
  - `_refreshDeviceState`
- Back to view (`home_shell.dart` or view helper):
  - `dayStripController`
  - `_jumpDayStripToDate`
  - `_scrollDayStripToDate`
  - all `WidgetsBinding.instance.addPostFrameCallback(...)`

### 3. Attachment and image flow

**Current issues**
- `lib/views/home/widgets/attachment_editing_helpers.dart` dang tron UI flow voi file processing.
- `lib/views/home/image_attachment_editor.dart` chua engine xu ly anh ben trong widget.

**Target split**
- Giu dialog/sheet/navigation/snackbar o view.
- Dua import/process/render bytes vao service.

**Functions / logic to move**
- To `lib/services/attachment_import_service.dart`:
  - `pickAttachments` phan doc file va tao `EventAttachment`
  - `attachmentFromXFile`
  - `convertImageAttachmentToPdf`
  - `_attachmentFromPlatformFile`
- Keep in view:
  - `askScanOutputMode`
  - `editAttachment`
  - `showAttachmentFailure`
- To `lib/services/image_edit_service.dart`:
  - `_saveAttachment`
  - `_mapPointIntoCrop`
  - `_decodeUiImage`
  - `_containSize`
  - hit-test logic
  - crop/render pipeline
  - `_OverlayAction`
  - `_StrokeAction`
  - `_TextAction`

### 4. Models and presenter boundaries

**Current issues**
- `LocalCachePayload` dang nam trong `local_cache_service.dart`.
- DTO/result object dang nam trong `home_flow_models.dart` du ten file nam duoi `controllers/`.
- Presentation mapping thoi tiet dang nam trong `weather_service.dart`.

**Target split**
- Chuyen `LocalCachePayload` sang `lib/models/local_cache_payload.dart`.
- Chuyen DTO/result object sang `lib/models/`.
- Chuyen weather presentation mapping sang `lib/utils/weather_presenter.dart`.

**Specific moves**
- From `local_cache_service.dart`:
  - `LocalCachePayload` -> `lib/models/local_cache_payload.dart`
- From `home_flow_models.dart`:
  - `CredentialsResult`
  - `TaskEditorResult`
  - `NoteEditorResult`
  - `EmailAuthResult`
  - `HomeActionResult`
  - `AttachmentOpenResult`
  - `WeatherPresentation`
- From `weather_service.dart`:
  - `iconForCode`
  - `descriptionForCode`
  - `suggestionsForDay`

## Safe Phasing

### Phase 1

- Move `LocalCachePayload`
- Move `WeatherPresentation`
- Move `HomeActionResult`
- Move `AttachmentOpenResult`

**Goal:** lam sach ranh gioi model/result ma rui ro thap.

### Phase 2

- Create `lib/utils/grade_metrics.dart`
- Create `lib/utils/curriculum_presenter.dart`
- Update grades views de dung util moi

**Goal:** rut business logic ra khoi view ma chua can them controller moi.

### Phase 3

- Introduce `lib/controllers/grades_controller.dart` neu tab diem van tiep tuc lon
- Gop GPA planner, metric, va filter state vao grades controller

**Goal:** dong nhat ranh gioi MVC cho tab diem.

### Phase 4

- Introduce `event_mutation_service.dart`
- Introduce `dashboard_persistence_service.dart`
- Introduce `school_sync_coordinator.dart`
- Introduce `device_effects_service.dart`
- Lam mong `HomeController`

**Goal:** cat nho `HomeController` theo use case.

### Phase 5

- Dua `ScrollController`
- Dua `jump/animate day strip`
- Dua `post frame callback`
  ve `home_shell.dart`

**Goal:** tra UI concern ve view layer.

### Phase 6

- Introduce `attachment_import_service.dart`
- Introduce `image_edit_service.dart`
- Giữ navigation/dialog/snackbar o view

**Goal:** tach file/media processing khoi widget.

## Acceptance Criteria

- View khong con chua business logic lon co the test doc lap.
- Controller khong con om UI concern nhu `ScrollController`, `WidgetsBinding`, `Navigator`, `SnackBar`, `showDialog`.
- Service khong phu thuoc widget tree va khong tra ve UI type neu co the tranh duoc.
- DTO/result/model duoc dat o vi tri trung lap ro rang, khong nam trong file service/controller neu ban chat la model.
- `HomeController` tap trung vao screen state va orchestration cap cao, khong con chi tiet low-level.
- Tab `grades` co duong ro rang de test metric va planner ma khong can widget test nang.

## Risks

- Tach qua nhieu trong mot dot co the gay hoi quy o sync, attachment, hoac local-first behavior.
- Refactor `HomeController` co nguy co vo cac rule nghiep vu quan trong neu khong co test bao ve.
- Dua qua nhieu file moi vao qua som co the lam codebase phuc tap hon muc can thiet.

## Guardrails

- Moi phase phai giu nguyen hanh vi nguoi dung.
- Sau moi phase, chay toi thieu `flutter analyze` va `flutter test`.
- Khong gom `attachment + cache + sync` vao cung mot patch lon neu chua co test du.
- Neu mot de xuat tach moi khong giam do phuc tap ro rang, dung lai va khong them file moi.

## Suggested Review Order

1. Models and typed result boundary cleanup
2. Grades metrics and curriculum presenter extraction
3. Home controller decomposition
4. UI concern move-back to view
5. Attachment and image processing split

## Usage

- Tai lieu nay la **target architecture spec**, khong phai current-state context file.
- Dung no de lap ke hoach refactor theo pha, review proposal, hoac giao task cho agent khac.
- Khong xem no la source of truth cho code hien tai; source of truth cho hien tai van la:
  - `docs/project-structure.md`
  - `_bmad-output/project-context.md`
  - code dang chay trong `lib/`
