# Inventory component - mobile-app

**Part ID:** `mobile-app`  
**Pham vi:** `lib/features/**`, `android/app/src/main/**`

## Tong quan

App Flutter da chuyen sang feature-first, nen component nay gom theo feature
thay vi theo `views/` cu. UI tat ca van biet render theo Material 3, nhung
phan state / orchestration da nam o Riverpod controller.

## Nhom dieu huong va shell

### `HomeShell`

- **File:** `lib/features/home/ui/home_shell.dart`
- **Vai tro:** shell dieu huong 5 tab, doc `HomeController` tu provider,
  tao `NavigationBar` va xu ly dialog/sheet/snackbar

### `HomeController`

- **File:** `lib/features/home/ui/home_controller.dart`
- **Vai tro:** controller trung tam cua app, cap nhat `HomeState`, dong bo
  local/cloud va dieu phoi widget/notification

## Nhom lich va event

### `SchedulePage`

- **File:** `lib/features/home/ui/pages/schedule_page.dart`
- **Vai tro:** man hinh lich chinh theo ngay

### Thanh phan lich

- weather card: forecast 7 ngay
- day strip: chon ngay dang pill
- event cards: hien thi note/task/attachment/done state
- editors: mo note/task editor va image attachment editor

## Nhom dong bo va tai khoan

### `SyncPage`

- **File:** `lib/features/home/ui/pages/sync_page.dart`
- **Vai tro:** trigger dong bo du lieu truong, xem profile va metrics

### `AccountPage`

- **File:** `lib/features/home/ui/pages/account_page.dart`
- **Vai tro:** dang nhap Google/email-password, sign out, giai thich offline /
  cloud mode

### `AccountAuthController`

- **File:** `lib/features/auth/ui/account_auth_controller.dart`
- **Vai tro:** provider-backed auth state va auth flow

## Nhom bang diem va planner

### `GradesPage`

- **File:** `lib/features/grades/ui/grades_page.dart`
- **Vai tro:** tong quan GPA, danh sach diem, planner va curriculum dialog

### `GradesController`

- **File:** `lib/features/grades/ui/grades_controller.dart`
- **Vai tro:** cap nhat state cua tab diem

### `GoalPlannerSection`

- **File:** `lib/features/grades/ui/widgets/goal_planner_section.dart`
- **Vai tro:** tinh lo trinh GPA muc tieu va goi y hoc lai / chon mon chac A

### `CurriculumSubjectsSection`

- **File:** `lib/features/grades/ui/widgets/curriculum_subjects_section.dart`
- **Vai tro:** render chuong trinh dao tao va nhom mon theo presentation order

## Nhom editor, sheet, dialog

### `ImageAttachmentEditor`

- **File:** `lib/features/attachments/ui/image_attachment_editor.dart`
- **Vai tro:** chinh sua anh dinh kem, crop, ve, them chu, undo, export lai

### `home_dialogs.dart`

- **File:** `lib/features/home/ui/widgets/home_dialogs.dart`
- **Vai tro:** month picker, sync credentials, email auth sheet

### `home_editors.dart`

- **File:** `lib/features/home/ui/widgets/home_editors.dart`
- **Vai tro:** note editor va task editor

### `home_flow_models.dart`

- **File:** `lib/features/home/domain/home_flow_models.dart`
- **Vai tro:** model tra ve tu dialog/sheet

## Nhom reusable/shared UI

### `home_common_widgets.dart`

- **File:** `lib/features/home/ui/widgets/home_common_widgets.dart`
- **Vai tro:** empty state, placeholder info, desktop-friendly scroll behavior

### `app_theme.dart`

- **File:** `lib/theme/app_theme.dart`
- **Vai tro:** theme dung chung toan app

## Nhom attachment

### `AttachmentStorageService`

- **File:** `lib/features/attachments/data/attachment_storage_service.dart`
- **Vai tro:** luu, doc va don dep attachment local-first

### `AttachmentImportService`

- **File:** `lib/features/attachments/data/attachment_import_service.dart`
- **Vai tro:** nhap attachment tu file picker, camera va PDF

### `AttachmentOpener`

- **File:** `lib/features/attachments/data/attachment_opener.dart`
- **Vai tro:** mo attachment theo platform qua io/web/stub

### `ImageEditService`

- **File:** `lib/features/attachments/data/image_edit_service.dart`
- **Vai tro:** decode, crop va render anh da chinh sua

## Nhom native/platform

### Android home widget

- **Files:** `MainActivity.kt`, `TodayScheduleWidgetProvider.kt`,
  `today_schedule_widget.xml`
- **Vai tro:** widget lich hom nay ngoai man hinh chinh Android
- **Tich hop:** nhan du lieu tu `WidgetSyncService` qua `MethodChannel`

## Muc do tai su dung

### Reusable cao

- empty / placeholder cards
- sync / account metric cards
- event card primitives
- curriculum subject cards

### Screen-specific

- `GoalPlannerSection`
- `ImageAttachmentEditor`
- `SchedulePage`
- `GradesPage`

## Design notes

- UI dang dung Material 3 va nhieu card bo tron lon.
- Tab lich la phan giu component nhieu nhat va cung la noi gan nhieu callback
  nhat.
- Da chuyen khoi `views/` cu sang `features/` de UI va state nam cung feature.

---

_Inventory nay da duoc cap nhat de khop voi feature-first tree hien tai._

