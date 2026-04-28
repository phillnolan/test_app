# Kien truc - mobile-app

**Part ID:** `mobile-app`  
**Loai:** `mobile`  
**Root:** `.`  
**Entry point:** `lib/main.dart`

## Muc dich

`mobile-app` la ung dung Flutter cho sinh vien:

- dong bo du lieu hoc tap tu cong truong;
- xem lich hoc, lich thi va weather theo ngay;
- xem diem, GPA planner va chuong trinh dao tao;
- tao note/task gan voi event;
- dinh kem anh, PDF va tep khac;
- dong bo du lieu ca nhan len cloud khi dang nhap Firebase.

## Kien truc tong the

App hien tai di theo feature-first layered architecture:

- **UI:** `lib/features/**/ui/`
- **Data:** `lib/features/**/data/`
- **Domain:** `lib/features/**/domain/` khi feature can logic chuyen hoa
- **Shared code:** `lib/models/`, `lib/services/`, `lib/theme/`, `lib/utils/`

Riverpod quan ly ownership cho state:

- `HomeController` la `Notifier<HomeState>` va duoc cung cap qua
  `homeControllerProvider`.
- `AccountAuthController` duoc cung cap qua `accountAuthControllerProvider`.
- UI doc state bang `ref.watch`, callback dung `ref.read`.

## Bootstrap

### 1. `lib/main.dart`

- khoi tao Flutter binding;
- thu khoi tao Firebase bang `DefaultFirebaseOptions.currentPlatform`;
- khoi tao notification service;
- boc app bang `ProviderScope`;
- chay `StudentPlannerApp`.

Firebase failure khong chan app chay o cac nen tang chua cau hinh day du.

### 2. `lib/app.dart`

- tao `MaterialApp`;
- set `Locale('vi', 'VN')`;
- nap theme tu `buildAppTheme()`;
- chon `HomeShell` lam man hinh goc.

## Cac thanh phan chinh

### `HomeShell`

- doc `HomeController` tu `homeControllerProvider`;
- dung `IndexedStack` de giu 5 tab;
- xu ly dialog, sheet, snackbar va day-strip scroll;
- la shell UI chinh cua app.

### `HomeController`

`HomeController` la trung tam dieu phoi cua app, nhung lifecycle do Riverpod
quan ly. No chiu trach nhiem:

- load local cache luc khoi dong;
- tai weather;
- giu `selectedDate`, `currentTab` va `HomeState`;
- dong bo truong;
- merge payload local/remote;
- persist attachment;
- dong bo note/task/attachment/snapshot len cloud;
- reschedule local notifications;
- cap nhat Android widget;
- phan ung khi auth state Firebase thay doi.

### `AccountAuthController`

- boc `AuthService` qua `accountAuthControllerProvider`;
- mo bottom sheet dang nhap email/password;
- xu ly Google Sign-In;
- sign out;
- giu cac flow auth rieng khoi `HomeController`.

### Service layer

- `SchoolApiService`: goi API truong;
- `LocalCacheService`: luu/tai `LocalCachePayload`;
- `CloudSyncService`: giao tiep voi Worker;
- `AttachmentStorageService`: persist file local-first;
- `NotificationService`: local notifications Android;
- `WidgetSyncService`: cap nhat home widget qua `MethodChannel`;
- `WeatherService`: goi Open-Meteo.

## State management

### Kieu state

- UI state: `currentTab`, `showSyncReminder`, `isLoading*`
- Domain state: `LocalCachePayload`, `WeatherForecast`
- Auth state: `User? signedInUser`
- Derived state: `allEvents`, indicator mau theo ngay, selected day events

### Chien luoc cap nhat

- Controller mutate private fields va emit snapshot `HomeState` qua Riverpod
  notifier.
- UI doc state qua `NotifierProvider`.
- Khong co repository/use case layer rieng o nhung flow hien tai.

## Cac luong chinh

### Luong khoi dong

1. `main()` khoi tao Firebase, notification va boc app bang `ProviderScope`.
2. `HomeShell` doc `homeControllerProvider` va goi `initialize()`.
3. `HomeController` load cache local, load weather, subscribe auth state va
   can day strip toi ngay hien tai.

### Luong dong bo du lieu truong

1. Nguoi dung mo tab dong bo.
2. `SyncPage` goi `HomeController.openSyncDialog()`.
3. App thu username/password sinh vien.
4. `SchoolApiService.sync()` lay profile, marks, timetable, exams va
   curriculum.
5. `HomeController` ghi vao `LocalCachePayload`.
6. App cap nhat lich, diem, notification va widget.

### Luong local-first + cloud sync

1. Moi thay doi event/task/note truoc tien duoc luu local.
2. `HomeController._persistPayload()` goi:
   - `LocalCacheService.save()`
   - `NotificationService.rescheduleForEvents()`
   - `WidgetSyncService.updateTodayWidget()`
3. Neu co Firebase user, `CloudSyncService` upload attachment, upsert note/task
   va luu snapshot dashboard len Worker.

### Luong attachment

1. Editor tao `EventAttachment` chua bytes/path.
2. `AttachmentStorageService` luu file trong documents directory.
3. `CloudSyncService.uploadAttachment()` upload len Worker neu user da dang nhap.
4. `EventAttachment.remoteKey` duoc luu lai de tai ve sau nay.

## UI va component structure

### Tab Lich

- `SchedulePage`
- hero card + weather card
- day strip ngang
- event cards
- note/task editors
- image attachment editor

### Tab Diem

- `GradesPage`
- GPA summary
- `GoalPlannerSection`
- `CurriculumSubjectsSection`

### Tab Dong bo

- `SyncPage`
- profile card
- metric cards

### Tab Tai khoan

- `AccountPage`
- dang nhap Google/email-password
- trang thai offline va cloud sync

## Tich hop ngoai

### TLU education API

- Host: `https://sinhvien1.tlu.edu.vn/education`
- Dung truc tiep tu app
- Khong di qua Worker

### Firebase

- Android va Web co `firebase_options.dart`
- App co the chay khi Firebase chua san sang
- Cloud sync yeu cau `FirebaseAuth.instance.currentUser`

### Cloudflare Worker

- URL mac dinh hard-code: `https://sinhvien-worker.nkocpk99012.workers.dev`
- Co the override bang `--dart-define=CLOUDFLARE_WORKER_URL=...`

### Open-Meteo

- Dung cho forecast 7 ngay o Ha Noi

## Nen tang va runtime

### Android

- ho tro camera
- local notifications
- home widget
- persist attachment vao file system

### Web

- co cau hinh Firebase Web
- khong co notification Android/widget
- mot so xu ly file degrade gracefully

## Rui ro va luu y

- `HomeController` van con kha lon, nen co the tiep tuc tach ra thanh cac
  service/controller nho hon khi repo lon hon.
- App goi truc tiep API truong bang tai khoan sinh vien, nen timeout/retry/error
  UX rat quan trong.
- Dong bo cloud hien khong chan local UX, nhung co the that bai am tham neu
  Worker loi.
- Test hien co da bao phu widget va controller co ban, nhung flow sync lon
  van nen tang coverage.

## Huong mo rong hop ly

- Tach cac flow con ra khoi `HomeController` khi use case du lon.
- Chuan hoa shared code vao `lib/core/`.
- Them test cho parsing API truong, cloud sync, planner GPA.
- Tiep tuc chuan hoa file nho, mot trach nhiem va naming theo Effective Dart.

---

_Kien truc nay phan anh trang thai mobile hien tai: feature-first + Riverpod,
khong con MVC._

