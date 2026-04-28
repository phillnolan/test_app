# Kiáº¿n trÃºc - mobile-app

**Part ID:** `mobile-app`  
**Loáº¡i:** `mobile`  
**Root:** `.`  
**Entry point:** `lib/main.dart`

## Má»¥c Ä‘Ã­ch

`mobile-app` lÃ  á»©ng dá»¥ng Flutter cho sinh viÃªn:

- Ä‘á»“ng bá»™ dá»¯ liá»‡u há»c táº­p tá»« cá»•ng trÆ°á»ng,
- xem lá»‹ch há»c/lá»‹ch thi theo ngÃ y,
- xem báº£ng Ä‘iá»ƒm vÃ  chÆ°Æ¡ng trÃ¬nh Ä‘Ã o táº¡o,
- táº¡o task cÃ¡ nhÃ¢n vÃ  ghi chÃº gáº¯n vÃ o sá»± kiá»‡n,
- Ä‘Ã­nh kÃ¨m áº£nh/PDF/tÃ i liá»‡u,
- Ä‘á»“ng bá»™ dá»¯ liá»‡u cÃ¡ nhÃ¢n lÃªn cloud khi Ä‘Äƒng nháº­p Firebase.

## Kiáº¿n trÃºc tá»•ng thá»ƒ

App Ä‘i theo mÃ´ hÃ¬nh MVC thá»±c dá»¥ng:

- **View:** náº±m trong `lib/views/**`
- **Controller:** náº±m trong `lib/controllers/**`
- **Model:** náº±m trong `lib/models/**`
- **Service/infrastructure:** náº±m trong `lib/services/**`

App hiện dùng Riverpod để quản lý ownership cho `HomeController`: logic nằm trong `HomeController` kế thừa `Notifier<HomeState>`, được cấp qua `NotifierProvider` và UI đọc state bằng `ref.watch` / `ref.listen`.

## Bootstrap

### 1. `lib/main.dart`

- khá»Ÿi táº¡o Flutter binding,
- thá»­ khá»Ÿi táº¡o Firebase báº±ng `DefaultFirebaseOptions.currentPlatform`,
- khá»Ÿi táº¡o `NotificationService`,
- cháº¡y `StudentPlannerApp`.

Firebase failure khÃ´ng cháº·n app cháº¡y trÃªn ná»n táº£ng chÆ°a cáº¥u hÃ¬nh; Ä‘Ã¢y lÃ  lá»±a chá»n há»— trá»£ cháº¿ Ä‘á»™ offline/local-only.

### 2. `lib/app.dart`

- táº¡o `MaterialApp`,
- set `Locale('vi', 'VN')`,
- náº¡p theme tá»« `buildAppTheme()`,
- chá»n `HomeShell` lÃ m mÃ n hÃ¬nh gá»‘c.

## CÃ¡c lá»›p vÃ  vai trÃ² chÃ­nh

### `HomeShell`

- Äá»c `HomeController` tá»« `homeControllerProvider`.
- Dá»±ng 4 tab qua `IndexedStack`:
  - Lá»‹ch
  - Äiá»ƒm
  - Äá»“ng bá»™
  - TÃ i khoáº£n
- Ná»‘i callback UI sang controller.

### `HomeController`

ÄÃ¢y lÃ  trung tÃ¢m Ä‘iá»u phá»‘i cá»§a app, nhÆ°ng lifecycle Ä‘Æ°á»£c Riverpod quáº£n lÃ½.
NÃ³ chá»‹u trÃ¡ch nhiá»‡m:

- load cache cá»¥c bá»™ lÃºc khá»Ÿi Ä‘á»™ng,
- táº£i thá»i tiáº¿t,
- giá»¯ `selectedDate`, `currentTab`, `payload`,
- xá»­ lÃ½ Ä‘á»“ng bá»™ cá»•ng trÆ°á»ng,
- merge payload local/remote,
- persist attachments,
- Ä‘á»“ng bá»™ note/task/attachments/snapshot lÃªn cloud,
- reschedule local notifications,
- cáº­p nháº­t Android widget,
- pháº£n á»©ng khi auth state Firebase thay Ä‘á»•i.

### `AccountAuthController`

- Bá»c `AuthService`
- Má»Ÿ bottom sheet Ä‘Äƒng nháº­p email/password
- Gá»i Ä‘Äƒng nháº­p Google
- Xá»­ lÃ½ sign out

### Service layer

- `SchoolApiService`: gá»i API trÆ°á»ng
- `LocalCacheService`: lÆ°u/táº£i `LocalCachePayload`
- `CloudSyncService`: giao tiáº¿p vá»›i Worker
- `AttachmentStorageService`: persist file vá» local storage
- `NotificationService`: notification Android
- `WidgetSyncService`: update home widget qua `MethodChannel`
- `WeatherService`: gá»i Open-Meteo

## State management

### Kiá»ƒu state

- UI state: `currentTab`, `showSyncReminder`, `isLoading*`
- Domain state: `LocalCachePayload`, `WeatherForecast`
- Auth state: `User? signedInUser`
- Derived state: `allEvents`, indicator mÃ u theo ngÃ y, selected day events

### Chiáº¿n lÆ°á»£c cáº­p nháº­t

- Controller mutate private fields và emit snapshot `HomeState` qua Riverpod notifier
- UI đọc state qua `NotifierProvider` được cấp bởi Riverpod
- KhÃ´ng cÃ³ lá»›p repository hoáº·c use case riÃªng

### ÄÃ¡nh giÃ¡

MÃ´ hÃ¬nh nÃ y dá»… theo dÃµi á»Ÿ quy mÃ´ hiá»‡n táº¡i, nhÆ°ng `HomeController` Ä‘ang Ã´m khÃ¡ nhiá»u trÃ¡ch nhiá»‡m. Náº¿u app tiáº¿p tá»¥c lá»›n lÃªn, Ä‘iá»ƒm Ä‘áº§u tiÃªn nÃªn tÃ¡ch lÃ :

- sync school data,
- cloud sync,
- event/task editing,
- weather/notifier widget orchestration.

## CÃ¡c luá»“ng chÃ­nh

### Luá»“ng khá»Ÿi Ä‘á»™ng

1. `main()` khá»Ÿi táº¡o Firebase, notification vÃ  bá»c app báº±ng `ProviderScope`.
2. `HomeShell` Ä‘á»c `homeControllerProvider` vÃ  gá»i `initialize()`.
3. `HomeController`:
   - load cache local,
   - load weather,
   - subscribe auth state,
   - cÄƒn day strip tá»›i ngÃ y hiá»‡n táº¡i.

### Luá»“ng Ä‘á»“ng bá»™ dá»¯ liá»‡u trÆ°á»ng

1. NgÆ°á»i dÃ¹ng má»Ÿ tab `Äá»“ng bá»™`.
2. `SyncPage` gá»i `HomeController.openSyncDialog()`.
3. App thu username/password sinh viÃªn.
4. `SchoolApiService.sync()`:
   - login láº¥y access token,
   - gá»i profile/marks/timetable/exams/curriculum,
   - chuáº©n hÃ³a thÃ nh `SchoolSyncSnapshot`.
5. `HomeController` ghi vÃ o `LocalCachePayload`.
6. App cáº­p nháº­t lá»‹ch, Ä‘iá»ƒm, notification vÃ  widget.

### Luá»“ng local-first + cloud sync

1. Má»i thay Ä‘á»•i event/task/note trÆ°á»›c tiÃªn Ä‘Æ°á»£c lÆ°u local.
2. `HomeController._persistPayload()` gá»i:
   - `LocalCacheService.save()`
   - `NotificationService.rescheduleForEvents()`
   - `WidgetSyncService.updateTodayWidget()`
3. Náº¿u cÃ³ Firebase user, `CloudSyncService`:
   - upload attachment thiáº¿u,
   - upsert note/task,
   - lÆ°u snapshot dashboard lÃªn Worker.

### Luá»“ng khÃ´i phá»¥c cloud

1. Khi auth state Ä‘á»•i sang signed-in, controller gá»i `_restoreAndSyncCloudState()`.
2. App Ä‘á»c `/sync-cache?key=dashboard` tá»« Worker.
3. Náº¿u snapshot remote má»›i hÆ¡n local, app Æ°u tiÃªn dÃ¹ng remote payload.

### Luá»“ng attachment

1. Editor táº¡o `EventAttachment` chá»©a bytes/path.
2. `AttachmentStorageService` persist file vá» documents directory trÃªn mobile.
3. `CloudSyncService.uploadAttachment()` upload file qua Worker náº¿u user Ä‘Ã£ Ä‘Äƒng nháº­p.
4. `EventAttachment.remoteKey` Ä‘Æ°á»£c lÆ°u láº¡i Ä‘á»ƒ táº£i vá» sau nÃ y.

## UI vÃ  component structure

### Tab Lá»‹ch

- `SchedulePage`
- hero card + weather card
- day strip ngang
- event cards
- note/task editors
- image attachment editor

### Tab Äiá»ƒm

- `GradesPage`
- `GradesHeroCard`
- `GoalPlannerSection`
- `CurriculumSubjectsDialog`

### Tab Äá»“ng bá»™

- `SyncPage`
- profile card
- metric cards

### Tab TÃ i khoáº£n

- `AccountPage`
- Ä‘Äƒng nháº­p Google/email-password
- tráº¡ng thÃ¡i offline vÃ  cloud sync

## TÃ­ch há»£p ngoÃ i

### TLU education API

- Host: `https://sinhvien1.tlu.edu.vn/education`
- DÃ¹ng trá»±c tiáº¿p tá»« app
- KhÃ´ng Ä‘i qua Worker

### Firebase

- Android vÃ  Web Ä‘Ã£ cÃ³ `firebase_options.dart`
- App cÃ³ thá»ƒ cháº¡y cáº£ khi Firebase chÆ°a sáºµn sÃ ng
- Cloud sync yÃªu cáº§u `FirebaseAuth.instance.currentUser`

### Cloudflare Worker

- URL máº·c Ä‘á»‹nh hard-code: `https://sinhvien-worker.nkocpk99012.workers.dev`
- CÃ³ thá»ƒ override báº±ng `--dart-define=CLOUDFLARE_WORKER_URL=...`

### Open-Meteo

- DÃ¹ng cho forecast 7 ngÃ y á»Ÿ HÃ  Ná»™i

## Ná»n táº£ng vÃ  khÃ¡c biá»‡t runtime

### Android

- há»— trá»£ camera
- local notifications
- home widget
- persist attachment vá» file system

### Web

- cÃ³ cáº¥u hÃ¬nh Firebase Web
- khÃ´ng cÃ³ notification Android/widget
- má»™t sá»‘ xá»­ lÃ½ file dÃ¹ng conditional import hoáº·c degrade gracefully

## Rá»§i ro vÃ  lÆ°u Ã½

- `HomeController` khÃ¡ lá»›n, dá»… trá»Ÿ thÃ nh Ä‘iá»ƒm ngháº½n maintainability.
- App gá»i trá»±c tiáº¿p API trÆ°á»ng báº±ng tÃ i khoáº£n sinh viÃªn, nÃªn timeout/retry/error UX ráº¥t quan trá»ng.
- Äá»“ng bá»™ cloud hiá»‡n khÃ´ng cháº·n theo káº¿t quáº£ response chi tiáº¿t; náº¿u Worker lá»—i, local UX váº«n á»•n nhÆ°ng Ä‘á»“ng bá»™ cÃ³ thá»ƒ Ã¢m tháº§m khÃ´ng hoÃ n táº¥t.
- `StudentPlannerApp` Ä‘Æ°á»£c test widget cÆ¡ báº£n, nhÆ°ng chÆ°a cÃ³ test sÃ¢u cho controller/service.

## HÆ°á»›ng má»Ÿ rá»™ng há»£p lÃ½

- TÃ¡ch `HomeController` thÃ nh nhiá»u controller/use-case theo module.
- Chuáº©n hÃ³a lá»›p repository cho local + remote sync.
- ThÃªm test cho parsing API trÆ°á»ng, cloud sync, planner GPA.
- TÃ¡ch attachment pipeline vÃ  weather ra service cÃ³ interface rÃµ hÆ¡n Ä‘á»ƒ test.

---

_Generated using BMAD Method `document-project` workflow_


