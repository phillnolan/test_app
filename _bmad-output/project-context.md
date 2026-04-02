---
project_name: 'sinhvien-app'
user_name: 'Nguyễn'
date: '2026-04-02T13:56:06.6301628+07:00'
sections_completed:
  [
    'technology_stack',
    'language_rules',
    'framework_rules',
    'testing_rules',
    'quality_rules',
    'workflow_rules',
    'anti_patterns',
  ]
existing_patterns_found: 8
status: 'complete'
rule_count: 28
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Flutter app: Dart SDK `^3.11.0`, Flutter Material app, locale mặc định `vi_VN`, `flutter_localizations`, `flutter_lints ^6.0.0`
- Auth và cloud trên app: `firebase_core ^4.6.0`, `firebase_auth ^6.3.0`, `google_sign_in ^7.2.0`
- Data/device integrations: `shared_preferences ^2.5.3`, `flutter_local_notifications ^19.4.2`, `timezone ^0.10.1`, `path_provider ^2.1.5`
- File và media: `file_picker ^10.3.2`, `image_picker ^1.1.2`, `image ^4.5.4`, `pdf ^3.11.3`, `open_filex ^4.7.0`
- Networking: `http ^1.5.0`, Open-Meteo API cho thời tiết, API trường TLU tại `https://sinhvien1.tlu.edu.vn/education`
- Cloudflare Worker: TypeScript `^5.8.3`, `wrangler ^4.11.1`, `jose ^6.0.10`, `@cloudflare/workers-types ^4.20260327.0`, `strict: true`, `compatibility_date = 2026-04-01`
- Lưu trữ cloud: D1 + KV + R2; Flutter worker URL đọc từ `String.fromEnvironment('CLOUDFLARE_WORKER_URL')` và đang có default production URL
- Kiến trúc app hiện tại: MVC thực dụng trong `lib/` với `views/`, `controllers/`, `models/`, `services/`, `utils/`, `theme/`

## Critical Implementation Rules

### Language-Specific Rules

- Giữ quy ước hiện tại: file `snake_case`, class/widget `PascalCase`, member private có tiền tố `_`.
- Parse JSON theo kiểu phòng thủ như code hiện có: dùng `whereType<Map>()`, `toString()`, `DateTime.tryParse()`, `int.tryParse()`; không giả định shape API ổn định.
- Mọi async flow đụng tới UI phải kiểm tra `context.mounted`; mọi callback muộn trong controller phải kiểm tra thêm `_isDisposed` trước `notifyListeners()` hoặc `SnackBar`.
- Với tác vụ fire-and-forget từ view/controller, dùng `unawaited(...)` như pattern đang có thay vì bỏ trôi `Future`.

### Framework-Specific Rules

- Tôn trọng MVC thực dụng của repo: `views` chỉ render và chuyển callback; `controllers` giữ state UI và điều phối flow; `services` chỉ xử lý kỹ thuật/tích hợp; `utils` phải là hàm thuần.
- Tính năng thuộc Home flow phải đi qua `HomeController` trước; không nhét sync/cache/cloud/business logic trực tiếp vào widget như `HomeShell`, `SchedulePage`, `SyncPage`, `AccountPage`.
- Tab `grades` hiện vẫn view-driven; chỉ thêm controller riêng khi logic tăng rõ rệt, không tạo tầng mới trước khi thật sự cần.
- Giữ offline-first boot: app vẫn phải chạy nếu Firebase init thất bại; local cache và weather được load song song; cloud chỉ bổ sung chứ không được chặn trải nghiệm local.
- State UI hiện dùng `ChangeNotifier` + `ListenableBuilder`; khi thêm state mới, cập nhật cùng phong cách này thay vì pha trộn state manager khác.
- Chức năng đa nền tảng phải dùng conditional import/export (`io`, `web`, `stub`) như `attachment_opener` và `http_client_factory`; không viết nhánh runtime làm vỡ compile target.

### Testing Rules

- Trước khi chốt thay đổi, chạy tối thiểu `flutter analyze` và `flutter test`.
- Ưu tiên test theo ranh giới hiện có: widget tests cho shell/tab/rendering, unit tests cho parsing/model/service; tránh test phụ thuộc mạng thật, Firebase thật, hoặc Cloudflare thật.
- Khi cần test service network, tận dụng constructor injection (`http.Client? client`) để mock/stub thay vì vá global state.

### Code Quality & Style Rules

- Giữ UI theo Material 3 theme có sẵn và copy tiếng Việt là mặc định; chỉ thêm tiếng Anh khi thật sự liên quan tới localization support.
- Sau mọi thao tác merge/persist event, luôn sort theo `start` như các flow hiện tại trước khi render, sync widget, hay reschedule notification.
- Muốn lưu payload học tập thì đi qua `LocalCachePayload` + `_persistPayload`; không tạo đường lưu riêng vào `SharedPreferences`, ngoại trừ dữ liệu widget trong `WidgetSyncService`.
- Dùng helper sẵn có cho date/event formatting và calendar math (`HomeCalendarUtils`, helper trong service/model); tránh nhân bản logic thời gian ở nhiều file.
- Bắt lỗi theo kiểu degrade gracefully: service ném exception typed, controller đổi thành thông báo thân thiện; lỗi weather/cloud/Firebase không được làm app chết hoặc mất local data.

### Development Workflow Rules

- `docs/project-structure.md` là tài liệu kiến trúc đang phản ánh code Flutter hiện tại; dùng nó làm nguồn mô tả tổ chức module.
- `cloudflare-worker/src/index.ts` mới là source of truth cho auth và endpoint; `cloudflare-worker/README.md` đang còn ghi chú scaffold cũ về auth.
- Giữ pattern cấu hình hiện tại: Worker URL override qua environment, bindings ở `wrangler.toml`, secret nằm ở Cloudflare/Firebase chứ không hard-code thêm vào app.
- Không commit credential trường học, Firebase token, hay secret Cloudflare; app chỉ được gửi Firebase Bearer token tới Worker và Worker mới quyết định truy cập dữ liệu theo `uid`.

### Critical Don't-Miss Rules

- Chỉ `personalTask` mới được xóa; event đồng bộ từ trường (`classSchedule`, `exam`) chỉ được thêm ghi chú/tệp đính kèm, không được cho xóa khỏi lịch.
- Khi sync sang tài khoản sinh viên khác, phải xóa `personalEvents` cũ như logic `_payloadFromSnapshot`; không carry task cá nhân giữa hai sinh viên.
- Cloud sync là best-effort và phụ thuộc auth: nếu chưa đăng nhập Firebase thì ghi chú local/offline vẫn phải hoạt động bình thường.
- Notification và home widget hiện chỉ là best-effort cho nền tảng hỗ trợ, chủ yếu Android; web hoặc platform không hỗ trợ phải no-op an toàn.
- Attachment flow phải hỗ trợ đủ ba trạng thái: file local, bytes/base64, và `remoteKey`; không được giả định luôn có filesystem hoặc luôn có mạng.
- Worker phải luôn giữ user scoping bằng Firebase `uid` cho notes/tasks/cache/attachments; không thêm endpoint hay query nào cho phép đọc chéo dữ liệu người dùng.

---

## Usage Guidelines

**Cho AI agents:**

- Đọc file này trước khi sửa code ở Flutter app hoặc Cloudflare Worker.
- Ưu tiên ranh giới MVC, local-first, và graceful degradation nếu gặp mâu thuẫn giữa nhiều hướng cài đặt.
- Nếu phát sinh pattern mới lặp lại nhiều nơi, cập nhật file này thay vì để tri thức nằm rải rác trong prompt tạm thời.

**Cho con người:**

- Cập nhật file khi đổi stack, đổi auth flow, hoặc đổi ranh giới module lớn.
- Giữ nội dung ngắn, chỉ lưu những rule dễ bị agent làm sai.
- Nếu README hoặc docs khác mâu thuẫn với code, ưu tiên sửa doc và cập nhật file này theo source code thật.

Last Updated: 2026-04-02T13:56:06.6301628+07:00
