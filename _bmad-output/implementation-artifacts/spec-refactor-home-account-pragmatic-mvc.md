---
title: 'Refactor home and account flows to pragmatic MVC'
type: 'refactor'
created: '2026-04-02T21:20:00+07:00'
status: 'done'
baseline_commit: '7e6c4541fe382813fa27b812bcb9b871103c69cb'
context:
  - 'docs/project-structure.md'
  - '_bmad-output/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Cac controller hien tai, dac biet la `HomeController` va `AccountAuthController`, dang mo dialog, bottom sheet, `SnackBar` va phu thuoc truc tiep vao `BuildContext`. Dieu nay lam mo ranh gioi MVC da duoc quy uoc trong project context, tang do ket dinh giua view va controller, va khien controller kho test hon.

**Approach:** Giữ kien truc MVC thuc dung cua repo va chi refactor cum `home/account` de view so huu toan bo UI flow ephemeral. Controller se nhan input da chuan hoa, dieu phoi service, cap nhat state, va tra ve ket qua typed de view tu quyet dinh dialog, message, va dieu huong hien thi.

## Boundaries & Constraints

**Always:** Giu nguyen hanh vi nguoi dung cho cac luong them viec, sua ghi chu, xoa viec ca nhan, dong bo du lieu truong, mo tep dinh kem, dang nhap email, dang nhap Google, va dang xuat. Giu `ChangeNotifier` + `ListenableBuilder`, local-first boot, sort event theo `start` sau moi lan persist, va rule chi `personalTask` moi duoc xoa. View duoc mo dialog/sheet/picker/snackbar; controller khong duoc mo them UI moi, khong duoc giu `BuildContext`, `Navigator`, hay `ScaffoldMessenger`.

**Ask First:** Dung va hoi nguoi dung neu phat hien can doi copy UX, can thay doi shape du lieu giua view va controller lam anh huong file khac ngoai cum `home/account`, hoac can tach them controller/service moi vuot qua pham vi refactor nho.

**Never:** Khong doi sang BLoC, Riverpod, MVVM hay them application layer moi. Khong refactor dong loat attachment, cache va cloud sync neu khong phuc vu truc tiep cho viec tach UI khoi controller. Khong doi logic nghiep vu sync, offline-first, auth, hay xoa event dong bo tu truong.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Move sync flow to view-owned UI | User bam dong bo, view thu duoc credentials hop le | View mo dialog, controller nhan credentials typed, sync thanh cong, state duoc cap nhat nhu truoc, view hien `SnackBar` thanh cong va chuyen ve tab lich | Neu service nem `SchoolApiException` hoac loi chung, controller tra ve ket qua loi typed de view hien dung thong diep va reset loading state |
| Move task and note editors to view-owned UI | User mo bottom sheet tao viec hoac sua event va bam luu/xoa | View thu duoc `TaskEditorResult` hoac `NoteEditorResult`, controller xu ly payload va notify, lich va event hien ra nhu truoc | Neu user huy sheet/dialog thi khong co thay doi state; neu yeu cau xoa event khong phai `personalTask` thi controller bo qua an toan |
| Move auth feedback to view-owned UI | User chon email auth, Google sign-in, hoac sign out | View mo sheet dang nhap email, goi controller voi ket qua da validate, controller thuc thi auth va tra ve ket qua typed de view hien `SnackBar` phu hop | Neu Firebase khong san sang hoac auth nem exception, view van o trang hien tai va hien thong diep loi than thien |
| Preserve attachment open flow | User bam mo tep dinh kem tu event | Controller xu ly doc local/cloud bytes va tra ket qua mo tep, view chi hien loi khi khong mo duoc | Neu local bytes, base64, va cloud deu that bai thi khong crash app, view hien thong bao that bai nhu hien tai |

</frozen-after-approval>

## Code Map

- `lib/controllers/home_controller.dart` -- controller trung tam dang chua state, UI flow, sync, persist va attachment; la diem refactor chinh
- `lib/controllers/account_auth_controller.dart` -- auth controller dang phu thuoc truc tiep vao `BuildContext` va `SnackBar`
- `lib/views/home/home_shell.dart` -- noi bind controller vao cac page va callback; se nhan them trach nhiem dieu phoi UI flow
- `lib/views/home/pages/schedule_page.dart` -- view lich dang goi callback them viec, sua event, mo month picker va mo attachment
- `lib/views/home/pages/sync_page.dart` -- view dong bo dang kich hoat sync; can nhan ket qua de hien feedback UI
- `lib/views/home/pages/account_page.dart` -- view tai khoan dang kich hoat auth flow; can chuyen sang mo sheet/dialog tai view
- `lib/views/home/widgets/home_dialogs.dart` -- chua month picker, sync credentials, email auth sheet; la UI entry point can giu o view layer
- `lib/views/home/widgets/home_editors.dart` -- chua task/note sheets; view layer se so huu invocation va gom ket qua tai day
- `lib/controllers/home_flow_models.dart` -- DTO va typed result chung cho view/controller, thay cho models nam duoi `views`
- `test/` -- bo sung unit/widget tests bao ve ranh gioi MVC vua tach va cac flow state quan trong

## Tasks & Acceptance

**Execution:**
- [x] `lib/controllers/home_controller.dart` -- tach cac method phu thuoc `BuildContext` thanh action nhan input typed va tra ve result typed cho sync, task, note, attachment, month pick -- dua controller ve dung vai tro dieu phoi state va nghiep vu
- [x] `lib/controllers/account_auth_controller.dart` -- thay cac method auth phu thuoc UI bang API nhan `EmailAuthResult` hoac action enum va tra ve ket qua typed -- loai bo `BuildContext` va `SnackBar` khoi auth controller
- [x] `lib/views/home/home_shell.dart` -- dua logic mo dialog/sheet/snackbar ve view shell va noi lai callback cho schedule, sync, account pages -- giu UI flow tai view layer nhung khong day nghiep vu xuong widget con
- [x] `lib/views/home/pages/schedule_page.dart` -- giu page chi render va phat su kien UI, callback van duoc shell dieu phoi lai cho month picker, task editor, note editor, delete confirm va attachment feedback
- [x] `lib/views/home/pages/sync_page.dart` -- tiep tuc la view kich hoat sync, con shell nhan ket qua typed va hien feedback UI -- dam bao loading va thong diep khong bi hoi quy
- [x] `lib/views/home/pages/account_page.dart` -- giu page la view kich hoat auth, con shell mo email sheet va hien feedback dang nhap/dang xuat -- dua auth UX ve dung tang
- [x] `test/` -- them hoac cap nhat test cho home/account controllers va widget wiring cua shell quanh cac ket qua typed, bao gom nhanh loi auth va rule xoa `personalTask`/doi sinh vien khi sync -- khoa hanh vi sau refactor
- [x] `docs/project-structure.md` -- cap nhat mo ta neu ranh gioi home/account thay doi ro hon sau refactor -- giu tai lieu dong bo voi code

**Acceptance Criteria:**
- Given nguoi dung mo month picker, task editor, note editor, sync credentials, hoac email auth, when thuc hien thao tac tu UI, then dialog/sheet duoc mo tu view layer va controller khong can `BuildContext`
- Given sync thanh cong hoac that bai, when view goi controller voi credentials hop le, then `HomeController` cap nhat state nhu cu va view hien dung thong diep thanh cong/loi ma khong doi copy
- Given nguoi dung tao, sua, toggle hoan thanh, hoac xoa viec ca nhan, when controller nhan du lieu typed tu view, then payload duoc persist, sort, dong bo thiet bi/cloud nhu cu, va chi `personalTask` moi duoc xoa
- Given nguoi dung dang nhap email, dang nhap Google, hoac dang xuat, when `AccountAuthController` xu ly action, then auth state thay doi nhu truoc va thong diep UI do view hien thi dua tren result typed
- Given mo tep dinh kem that bai, when controller khong mo duoc file local/cloud, then app khong crash va view hien thong bao that bai nhu hanh vi hien tai

## Spec Change Log

## Design Notes

Refactor nay nen theo huong “view owns ephemeral UI, controller owns intent and state”:

```text
HomeShell/View
  -> mo dialog/sheet/picker
  -> nhan typed result tu UI
  -> goi controller action
  -> doc controller result typed
  -> hien SnackBar / dieu huong

Controller
  -> validate nghiep vu
  -> goi services
  -> cap nhat payload/state
  -> tra status/result cho view
```

Ket qua typed co the la enum + message, hoac object nho cho tung flow. Muc tieu khong phai tao framework moi, ma chi tao seam ro rang de controller khong con phu thuoc widget tree.

## Verification

**Commands:**
- `flutter analyze` -- expected: khong con loi type/lint sau refactor MVC
- `flutter test` -- expected: test moi va test hien co deu pass

## Suggested Review Order

**UI orchestration**

- Home shell gio so huu toan bo dialog, sheet va snackbar thay cho controller.
  [`home_shell.dart:18`](../../lib/views/home/home_shell.dart#L18)

- Sync flow mo dialog o view, sau do goi controller bang credentials typed.
  [`home_shell.dart:221`](../../lib/views/home/home_shell.dart#L221)

- Auth sheet va feedback UI duoc giu tron ven o tang view.
  [`home_shell.dart:297`](../../lib/views/home/home_shell.dart#L297)

**Controller contracts**

- Typed result chung cat dut phu thuoc nguoc tu controller sang `views`.
  [`home_flow_models.dart:58`](../../lib/controllers/home_flow_models.dart#L58)

- Home controller chi con dieu phoi state, sync va ket qua nghiep vu.
  [`home_controller.dart:171`](../../lib/controllers/home_controller.dart#L171)

- Auth controller tra ket qua typed thay vi tu mo `SnackBar`.
  [`account_auth_controller.dart:23`](../../lib/controllers/account_auth_controller.dart#L23)

- Device sync duoc ha xuong best-effort de khong vo flow chinh.
  [`home_controller.dart:417`](../../lib/controllers/home_controller.dart#L417)

**Docs and verification**

- Tai lieu kien truc nay mo ta ro hon viec view so huu UI ngan han.
  [`project-structure.md:128`](../../docs/project-structure.md#L128)

- Test widget/controller khoa cac regression chinh cua refactor nay.
  [`widget_test.dart:24`](../../test/widget_test.dart#L24)

- Rule sync doi sinh vien khong duoc carry `personalEvents` duoc bao ve bang test.
  [`widget_test.dart:43`](../../test/widget_test.dart#L43)
