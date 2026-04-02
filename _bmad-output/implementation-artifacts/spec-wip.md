---
title: 'Refactor HomeController phase 4 service decomposition'
type: 'refactor'
created: '2026-04-02T22:30:00+07:00'
status: 'draft'
context:
  - 'docs/project-structure.md'
  - '_bmad-output/project-context.md'
  - '_bmad-output/implementation-artifacts/spec-target-mvc-refactor-roadmap.md'
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** `HomeController` van dang om qua nhieu trach nhiem cua Phase 4: school sync, local/cloud persistence, task-note mutation, attachment upload, notification/widget side effects. Viec nay lam controller kho test, kho doc, va de bi vo ranh gioi MVC da duoc roadmap va project context quy dinh.

**Approach:** Giu `HomeController` la screen controller, nhung tach cac use case co the test doc lap thanh service nho: `SchoolSyncCoordinator`, `DashboardPersistenceService`, `EventMutationService`, va `DeviceEffectsService`. Khong doi UX, khong day logic nguoc ve view, va khong refactor sang Phase 5 hay Phase 6 trong dot nay.

## Boundaries & Constraints

**Always:** Giu nguyen hanh vi nguoi dung cua cac flow sync truong, restore cloud best-effort, local-first boot, them/sua/xoa `personalTask`, toggle done, mo attachment, reschedule notification, va update widget. Sau moi lan persist hoac merge payload, event phai duoc sort theo `start`. Rule "chi `personalTask` moi duoc xoa" va rule "sync sang sinh vien khac thi xoa `personalEvents` cu" phai duoc giu nguyen. Service moi khong duoc phu thuoc `BuildContext`, widget tree, `Navigator`, `SnackBar`, hay `notifyListeners()`.

**Ask First:** Dung lai va hoi nguoi dung neu trong qua trinh tach service can doi copy UX, can chuyen them UI concern cua day strip/post-frame callback sang view som hon Phase 5, can doi shape DTO dang duoc su dung ngoai cum home, hoac gap xung dot truc tiep voi cac thay doi dang mo san trong working tree.

**Never:** Khong refactor lai phan Home/Account typed result da xong o spec truoc. Khong gom them Phase 5 hoac Phase 6 vao cung patch. Khong doi state management sang Provider/BLoC/Riverpod. Khong day business logic xuong `views/home/*`. Khong doi nghiep vu cloud/auth/offline-first hien co chi de "lam dep" kien truc.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| School sync success | Credentials hop le, snapshot tra ve profile/grades/events moi | Coordinator tao payload moi, xoa `personalEvents` neu doi sinh vien, persist qua dashboard persistence, controller cap nhat state va chon ngay sync nhu cu | N/A |
| School sync failure | `SchoolApiService.sync` nem `SchoolApiException` hoac loi chung | Controller tra `HomeActionResult.failure(...)`, khong mat local data dang co, loading state duoc reset | Bao toan payload local va thong diep loi than thien nhu hien tai |
| Event mutation | User them task, sua note, toggle done, hoac xoa task ca nhan | `EventMutationService` tra payload da persist, attachment duoc luu local truoc khi save, event da sort, cloud/device side effects duoc chay qua persistence path tap trung | Neu xoa event khong phai `personalTask` thi bo qua an toan; loi best-effort cloud khong duoc lam mat local data |
| Restore cloud cache | User da auth Firebase, cloud co cache moi hon local | Dashboard persistence quyet dinh co dung remote hay khong, persist lai local, giu local-first neu cloud hong | Neu fetch cloud that bai thi bo qua an toan va giu state local hien co |
| Open attachment fallback | Attachment co local path, bytes/base64, hoac `remoteKey` | Flow mo tep van uu tien local bytes, roi cloud/base64, view nhan typed result nhu cu | Neu tat ca cach deu that bai thi tra `AttachmentOpenResult` that bai, khong crash app |

</frozen-after-approval>

## Code Map

- `lib/controllers/home_controller.dart` -- screen controller dang chua ca orchestration va low-level use case; la file can lam mong
- `lib/controllers/home_flow_models.dart` -- input DTO cho sync/task/note; can duoc service moi tai su dung dung ranh gioi
- `lib/services/local_cache_service.dart` -- persistence local cap thap duoc `DashboardPersistenceService` bao quanh
- `lib/services/cloud_sync_service.dart` -- cloud cache, task/note upsert, upload/download attachment; la dependency chinh cua persistence va mutation
- `lib/services/school_api_service.dart` -- sync portal truong va tra `SchoolSyncSnapshot`; se duoc coordinator bao quanh
- `lib/services/attachment_storage_service.dart` -- persist/read attachment local; se duoc event mutation va attachment open tai su dung
- `lib/services/notification_service.dart` -- notification best-effort; se duoc gom vao device effects
- `lib/services/widget_sync_service.dart` -- home widget best-effort; se duoc gom vao device effects
- `lib/models/local_cache_payload.dart` -- payload trung tam di qua controller, persistence va sync
- `test/controllers/home_controller_test.dart` -- bo sung unit/widget tests khoa regression cua home controller sau khi tach service

## Tasks & Acceptance

**Execution:**
- [ ] `lib/services/device_effects_service.dart` -- tao service gom `NotificationService` va `WidgetSyncService`, expose mot API refresh device state cho payload da sort -- tach platform side effects khoi controller
- [ ] `lib/services/dashboard_persistence_service.dart` -- tao service cho load local cache, restore cloud state, persist payload, sync payload len cloud, quyet dinh remote/local, va selected date fallback -- tap trung hoa duong local-first + cloud best-effort
- [ ] `lib/services/school_sync_coordinator.dart` -- tao coordinator bao `SchoolApiService`, map `SchoolSyncSnapshot` thanh `LocalCachePayload`, va giu rule doi sinh vien thi xoa `personalEvents` -- tach school sync orchestration khoi controller
- [ ] `lib/services/event_mutation_service.dart` -- tao service cho add task, edit event, delete personal event, toggle done, open attachment, va upload missing attachments can thiet cho cloud -- dua mutation flow ve service co the test doc lap
- [ ] `lib/controllers/home_controller.dart` -- thay cac block low-level bang loi goi service moi, giu state screen, loading flag, auth listener, selected date, current tab va typed result -- tra controller ve dung vai tro orchestration cap cao
- [ ] `test/controllers/home_controller_test.dart` -- cap nhat hoac bo sung test bao ve school sync, rule xoa `personalTask`, best-effort cloud restore, va weather/selected date khong hoi quy -- khoa hanh vi sau refactor
- [ ] `docs/project-structure.md` -- cap nhat phan home services neu ranh gioi module thay doi ro hon sau Phase 4 -- giu doc dong bo voi code

**Acceptance Criteria:**
- Given app boot voi local cache ton tai, when `HomeController.initialize()` chay, then local cache van duoc load qua persistence service, selected date van duoc chon tu payload, va weather/auth flow hien co khong doi hanh vi
- Given user sync du lieu truong thanh cong, when coordinator nhan snapshot cua sinh vien moi, then payload moi duoc persist qua dashboard persistence, `personalEvents` cu bi xoa dung rule, va controller van tra thong diep thanh cong nhu truoc
- Given user them, sua, toggle, hoac xoa task ca nhan, when `HomeController` goi event mutation service, then payload duoc cap nhat dung, event duoc sort, local save van la source of truth, va cloud/device side effects chi la best-effort
- Given auth Firebase dang co va cloud cache moi hon local, when restore cloud state chay, then payload remote duoc ap dung an toan; neu cloud loi thi local data van duoc giu nguyen
- Given user mo attachment ma local path hong, when event mutation/open flow fallback sang bytes hoac remote, then ket qua mo file van giong hien tai; neu that bai thi view nhan `AttachmentOpenResult` that bai thay vi crash

## Spec Change Log

## Design Notes

Phase 4 nen tao mot seam ro rang nhu sau:

```text
HomeController
  -> SchoolSyncCoordinator
  -> EventMutationService
  -> DashboardPersistenceService
       -> LocalCacheService
       -> CloudSyncService
       -> DeviceEffectsService

View
  -> van noi callback typed nhu hien tai
```

Muc tieu cua cach tach nay la giu `HomeController` chi con quyet dinh state man hinh:

- bat/tat loading
- giu `_selectedDate`, `_currentTab`, `_signedInUser`
- lang nghe auth state
- tra `HomeActionResult` / `AttachmentOpenResult`

Phan service se giu chi tiet low-level va co API typed de test rieng, nhung khong tao application layer moi hay framework moi.

## Verification

**Commands:**
- `flutter analyze` -- expected: khong co loi type/lint sau khi them service va cap nhat import
- `flutter test` -- expected: test hien co va test bo sung cho home controller deu pass
