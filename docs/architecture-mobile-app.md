# Kiến trúc - mobile-app

**Part ID:** `mobile-app`  
**Loại:** `mobile`  
**Root:** `.`  
**Entry point:** `lib/main.dart`

## Mục đích

`mobile-app` là ứng dụng Flutter cho sinh viên:

- đồng bộ dữ liệu học tập từ cổng trường,
- xem lịch học/lịch thi theo ngày,
- xem bảng điểm và chương trình đào tạo,
- tạo task cá nhân và ghi chú gắn vào sự kiện,
- đính kèm ảnh/PDF/tài liệu,
- đồng bộ dữ liệu cá nhân lên cloud khi đăng nhập Firebase.

## Kiến trúc tổng thể

App đi theo mô hình MVC thực dụng:

- **View:** nằm trong `lib/views/**`
- **Controller:** nằm trong `lib/controllers/**`
- **Model:** nằm trong `lib/models/**`
- **Service/infrastructure:** nằm trong `lib/services/**`

Không có state management framework riêng như Provider/Bloc/Redux; thay vào đó `HomeController` kế thừa `ChangeNotifier` và được nối thẳng vào UI bằng `ListenableBuilder`.

## Bootstrap

### 1. `lib/main.dart`

- khởi tạo Flutter binding,
- thử khởi tạo Firebase bằng `DefaultFirebaseOptions.currentPlatform`,
- khởi tạo `NotificationService`,
- chạy `StudentPlannerApp`.

Firebase failure không chặn app chạy trên nền tảng chưa cấu hình; đây là lựa chọn hỗ trợ chế độ offline/local-only.

### 2. `lib/app.dart`

- tạo `MaterialApp`,
- set `Locale('vi', 'VN')`,
- nạp theme từ `buildAppTheme()`,
- chọn `HomeShell` làm màn hình gốc.

## Các lớp và vai trò chính

### `HomeShell`

- Tạo một `HomeController` duy nhất.
- Dựng 4 tab qua `IndexedStack`:
  - Lịch
  - Điểm
  - Đồng bộ
  - Tài khoản
- Nối callback UI sang controller.

### `HomeController`

Đây là trung tâm điều phối của app. Nó chịu trách nhiệm:

- load cache cục bộ lúc khởi động,
- tải thời tiết,
- giữ `selectedDate`, `currentTab`, `payload`,
- xử lý đồng bộ cổng trường,
- merge payload local/remote,
- persist attachments,
- đồng bộ note/task/attachments/snapshot lên cloud,
- reschedule local notifications,
- cập nhật Android widget,
- phản ứng khi auth state Firebase thay đổi.

### `AccountAuthController`

- Bọc `AuthService`
- Mở bottom sheet đăng nhập email/password
- Gọi đăng nhập Google
- Xử lý sign out

### Service layer

- `SchoolApiService`: gọi API trường
- `LocalCacheService`: lưu/tải `LocalCachePayload`
- `CloudSyncService`: giao tiếp với Worker
- `AttachmentStorageService`: persist file về local storage
- `NotificationService`: notification Android
- `WidgetSyncService`: update home widget qua `MethodChannel`
- `WeatherService`: gọi Open-Meteo

## State management

### Kiểu state

- UI state: `currentTab`, `showSyncReminder`, `isLoading*`
- Domain state: `LocalCachePayload`, `WeatherForecast`
- Auth state: `User? signedInUser`
- Derived state: `allEvents`, indicator màu theo ngày, selected day events

### Chiến lược cập nhật

- Controller mutate state và gọi `notifyListeners()`
- UI đọc state trực tiếp qua controller
- Không có lớp repository hoặc use case riêng

### Đánh giá

Mô hình này dễ theo dõi ở quy mô hiện tại, nhưng `HomeController` đang ôm khá nhiều trách nhiệm. Nếu app tiếp tục lớn lên, điểm đầu tiên nên tách là:

- sync school data,
- cloud sync,
- event/task editing,
- weather/notifier widget orchestration.

## Các luồng chính

### Luồng khởi động

1. `main()` khởi tạo Firebase và notification.
2. `HomeShell` tạo `HomeController` và gọi `initialize()`.
3. `HomeController`:
   - load cache local,
   - load weather,
   - subscribe auth state,
   - căn day strip tới ngày hiện tại.

### Luồng đồng bộ dữ liệu trường

1. Người dùng mở tab `Đồng bộ`.
2. `SyncPage` gọi `HomeController.openSyncDialog()`.
3. App thu username/password sinh viên.
4. `SchoolApiService.sync()`:
   - login lấy access token,
   - gọi profile/marks/timetable/exams/curriculum,
   - chuẩn hóa thành `SchoolSyncSnapshot`.
5. `HomeController` ghi vào `LocalCachePayload`.
6. App cập nhật lịch, điểm, notification và widget.

### Luồng local-first + cloud sync

1. Mọi thay đổi event/task/note trước tiên được lưu local.
2. `HomeController._persistPayload()` gọi:
   - `LocalCacheService.save()`
   - `NotificationService.rescheduleForEvents()`
   - `WidgetSyncService.updateTodayWidget()`
3. Nếu có Firebase user, `CloudSyncService`:
   - upload attachment thiếu,
   - upsert note/task,
   - lưu snapshot dashboard lên Worker.

### Luồng khôi phục cloud

1. Khi auth state đổi sang signed-in, controller gọi `_restoreAndSyncCloudState()`.
2. App đọc `/sync-cache?key=dashboard` từ Worker.
3. Nếu snapshot remote mới hơn local, app ưu tiên dùng remote payload.

### Luồng attachment

1. Editor tạo `EventAttachment` chứa bytes/path.
2. `AttachmentStorageService` persist file về documents directory trên mobile.
3. `CloudSyncService.uploadAttachment()` upload file qua Worker nếu user đã đăng nhập.
4. `EventAttachment.remoteKey` được lưu lại để tải về sau này.

## UI và component structure

### Tab Lịch

- `SchedulePage`
- hero card + weather card
- day strip ngang
- event cards
- note/task editors
- image attachment editor

### Tab Điểm

- `GradesPage`
- `GradesHeroCard`
- `GoalPlannerSection`
- `CurriculumSubjectsDialog`

### Tab Đồng bộ

- `SyncPage`
- profile card
- metric cards

### Tab Tài khoản

- `AccountPage`
- đăng nhập Google/email-password
- trạng thái offline và cloud sync

## Tích hợp ngoài

### TLU education API

- Host: `https://sinhvien1.tlu.edu.vn/education`
- Dùng trực tiếp từ app
- Không đi qua Worker

### Firebase

- Android và Web đã có `firebase_options.dart`
- App có thể chạy cả khi Firebase chưa sẵn sàng
- Cloud sync yêu cầu `FirebaseAuth.instance.currentUser`

### Cloudflare Worker

- URL mặc định hard-code: `https://sinhvien-worker.nkocpk99012.workers.dev`
- Có thể override bằng `--dart-define=CLOUDFLARE_WORKER_URL=...`

### Open-Meteo

- Dùng cho forecast 7 ngày ở Hà Nội

## Nền tảng và khác biệt runtime

### Android

- hỗ trợ camera
- local notifications
- home widget
- persist attachment về file system

### Web

- có cấu hình Firebase Web
- không có notification Android/widget
- một số xử lý file dùng conditional import hoặc degrade gracefully

## Rủi ro và lưu ý

- `HomeController` khá lớn, dễ trở thành điểm nghẽn maintainability.
- App gọi trực tiếp API trường bằng tài khoản sinh viên, nên timeout/retry/error UX rất quan trọng.
- Đồng bộ cloud hiện không chặn theo kết quả response chi tiết; nếu Worker lỗi, local UX vẫn ổn nhưng đồng bộ có thể âm thầm không hoàn tất.
- `StudentPlannerApp` được test widget cơ bản, nhưng chưa có test sâu cho controller/service.

## Hướng mở rộng hợp lý

- Tách `HomeController` thành nhiều controller/use-case theo module.
- Chuẩn hóa lớp repository cho local + remote sync.
- Thêm test cho parsing API trường, cloud sync, planner GPA.
- Tách attachment pipeline và weather ra service có interface rõ hơn để test.

---

_Generated using BMAD Method `document-project` workflow_
