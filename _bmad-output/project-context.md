---
project_name: 'sinhvien-app'
user_name: 'Nguyễn'
date: '2026-04-02T22:00:00+07:00'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'quality_rules', 'workflow_rules', 'anti_patterns']
existing_patterns_found: 8
status: 'complete'
rule_count: 70
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Flutter app: Dart SDK `^3.11.0`, Flutter Material app, `flutter_localizations`, `flutter_lints ^6.0.0`
- Auth và cloud trên app: `firebase_core ^4.6.0`, `firebase_auth ^6.3.0`, `google_sign_in ^7.2.0`
- Lưu trữ và tích hợp thiết bị: `shared_preferences ^2.5.3`, `flutter_local_notifications ^19.4.2`, `timezone ^0.10.1`, `path_provider ^2.1.5`
- File và media: `file_picker ^10.3.2`, `image_picker ^1.1.2`, `image ^4.5.4`, `pdf ^3.11.3`, `open_filex ^4.7.0`
- Networking: `http ^1.5.0`, Open-Meteo API, API trường TLU tại `https://sinhvien1.tlu.edu.vn/education`
- Cloudflare Worker: TypeScript `^5.8.3`, `wrangler ^4.11.1`, `jose ^6.0.10`, `@cloudflare/workers-types ^4.20260327.0`, `strict: true`, `compatibility_date = 2026-04-01`
- Lưu trữ cloud: D1 + KV + R2; Flutter app đọc Worker URL từ `String.fromEnvironment('CLOUDFLARE_WORKER_URL')`
- Kiến trúc app trong `lib/`: Flutter MVC thực dụng với `views/`, `controllers/`, `models/`, `services/`, `utils/`, `theme/`
- State management hiện tại: `ChangeNotifier` + `ListenableBuilder`, không dùng Provider/BLoC/Riverpod
- Định hướng refactor hiện tại: tiếp tục giữ MVC thực dụng, không thêm tầng trung gian mới nếu chưa có nhu cầu rõ ràng

## Critical Implementation Rules

### Language-Specific Rules

- Giữ quy ước hiện tại: file `snake_case`, class/widget `PascalCase`, member private có tiền tố `_`.
- Ưu tiên model typed và `copyWith`; không lan `dynamic` ra ngoài biên parse/integration.
- Parse JSON theo kiểu phòng thủ như code hiện có: dùng `whereType<Map>()`, `toString()`, `DateTime.tryParse()`, `int.tryParse()`, `double.tryParse()`; không giả định shape API luôn ổn định.
- Với dữ liệu lấy từ API trường hoặc cloud, normalize ngay trong service hoặc mapper trước khi trả về controller.
- Mọi async flow có thể chạm UI phải kiểm tra `context.mounted`; mọi callback muộn trong controller phải kiểm tra `_isDisposed` trước `notifyListeners()` hoặc side effect tiếp theo.
- Với tác vụ fire-and-forget từ view/controller, dùng `unawaited(...)` thay vì bỏ trôi `Future`.
- Khi cập nhật state từ kết quả async, gán state tập trung rồi mới `notifyListeners()`; tránh notify nhiều nhịp nhỏ nếu không cần thiết.
- Dữ liệu đi qua controller nên ưu tiên immutable update: map/copy danh sách thay vì mutate trực tiếp object đang render.
- Không truyền `BuildContext` xuống `services` hoặc `models`; `BuildContext` chỉ nên nằm ở `views`.
- Nếu cần DTO cho flow UI như form result hoặc action result, tách thành lớp typed riêng thay vì dùng `Map<String, dynamic>` ad-hoc.

### Framework-Specific Rules

- Tôn trọng MVC thực dụng của repo: `views` chỉ render và nhận input; `controllers` giữ state UI và điều phối flow; `services` chỉ xử lý kỹ thuật/tích hợp; `utils` phải là hàm thuần.
- Giữ state management hiện tại: `ChangeNotifier` + `ListenableBuilder`; không trộn thêm Provider, BLoC, Riverpod, MVVM hoặc state manager khác trong cùng đợt thay đổi.
- `BuildContext`, `Navigator`, `showDialog`, `showModalBottomSheet`, `ScaffoldMessenger` phải nằm ở `views`; controller chỉ nhận input đã chuẩn hóa và trả về state hoặc result typed.
- `views/home/*` không được gọi trực tiếp `SchoolApiService`, `CloudSyncService`, `LocalCacheService`, `AuthService` hoặc service hạ tầng khác.
- `HomeController` là controller cấp màn hình cho toàn bộ home shell; không đẩy thêm parse API, persistence low-level hoặc widget rendering logic mới vào đây.
- `services` không được giữ state UI, không `notifyListeners()`, và không phụ thuộc widget tree.
- Logic trình bày đã được controller chuẩn hóa thì view chỉ render lại; ví dụ dữ liệu thời tiết hiển thị nên đi qua presentation model thay vì gọi service thời tiết trực tiếp từ page.
- Tab `grades` hiện còn view-driven; chỉ thêm controller riêng khi logic tính toán hoặc lọc dữ liệu tăng đủ lớn để cần test và tái sử dụng riêng.
- Với tính năng đa nền tảng, tiếp tục dùng conditional import/export theo pattern `io`, `web`, `stub`; không dùng runtime branch làm vỡ compile target.
- Giữ offline-first boot: app vẫn phải chạy nếu Firebase init thất bại; local cache và weather được load song song; cloud chỉ bổ sung chứ không chặn trải nghiệm local.

### Testing Rules

- Trước khi chốt thay đổi, chạy tối thiểu `flutter analyze` và `flutter test`.
- Ưu tiên test theo ranh giới MVC hiện có: widget tests cho `views`, unit tests cho `controllers`, `models`, `services`; tránh test xuyên nhiều tầng nếu không cần thiết.
- Repo hiện có coverage còn mỏng; với mọi thay đổi có logic đáng kể, bổ sung test ngay ở ranh giới vừa sửa thay vì dựa vào bộ test hiện có.
- Với refactor MVC, nếu kéo logic khỏi view sang controller hoặc utils thì phải thêm test riêng cho phần logic vừa tách ra.
- Widget test nên tập trung vào render, callback wiring, trạng thái rỗng/loading/error và tương tác cơ bản; không nhét business logic nặng vào widget test.
- Controller test nên ưu tiên các flow state transition: load cache, đổi tab, chọn ngày, toggle done, merge payload, xử lý success/error từ service.
- Service test nên cô lập tích hợp ngoài bằng fake hoặc stub; không dùng mạng thật, Firebase thật hoặc Cloudflare thật trong test thường xuyên.
- Trong repo này, ưu tiên fake subclass đơn giản như các test hiện có thay vì đưa thêm mocking framework mới nếu chưa thật sự cần.
- Khi test parsing dữ liệu trường hoặc cloud payload, luôn có case cho dữ liệu thiếu field, sai kiểu hoặc null để giữ parsing phòng thủ.
- Sau mọi refactor lớn ở `HomeController`, phải có test bảo vệ các rule nghiệp vụ quan trọng như: chỉ `personalTask` mới được xóa, sync sang sinh viên khác phải xóa `personalEvents`, lỗi cloud không làm mất local data.

### Code Quality & Style Rules

- Giữ UI theo Material 3 theme hiện có; copy tiếng Việt là mặc định.
- Sau mọi thao tác merge hoặc persist event, luôn sort theo `start` trước khi render, sync widget hoặc reschedule notification.
- Muốn lưu payload học tập thì đi qua `LocalCachePayload` và đường persist tập trung; không tạo đường lưu riêng rải rác.
- Dùng helper sẵn có cho date/event formatting và calendar math; không nhân bản logic thời gian ở nhiều file.
- Bắt lỗi theo kiểu graceful degradation: service ném exception typed, controller đổi thành state hoặc result thân thiện; lỗi weather/cloud/Firebase không được làm app chết hoặc mất local data.
- Mỗi file nên có một trách nhiệm chính đúng tầng MVC; nếu một file vừa parse dữ liệu, vừa giữ state, vừa dựng UI thì xem đó là tín hiệu cần tách.
- Không thêm helper “tiện tay” vào `views` nếu logic đó có thể tái sử dụng hoặc cần test độc lập; chuyển sang `controller`, `service` hoặc `utils` theo đúng bản chất.
- Nếu controller bắt đầu phình to, ưu tiên tách theo use case hoặc service nhỏ thay vì đẩy ngược logic xuống widget.
- Tên hàm trong controller nên thể hiện ý định người dùng hoặc flow nghiệp vụ như `syncSchoolData`, `reloadWeather`, `toggleDone`; tránh tên mơ hồ kiểu `handleStuff`, `doProcess`.
- Khi refactor MVC, ưu tiên thay đổi nhỏ và giữ nguyên hành vi cũ; không trộn refactor kiến trúc với thay đổi UI lớn trong cùng một đợt.

### Development Workflow Rules

- `docs/project-structure.md` là tài liệu mô tả ranh giới module Flutter hiện tại; dùng nó làm source of truth cho cấu trúc app nếu không có thay đổi code mới hơn.
- Khi tài liệu và code mâu thuẫn, ưu tiên code đang chạy đúng; sau đó cập nhật lại doc và `project-context.md` cho khớp.
- `cloudflare-worker/src/index.ts` là source of truth cho auth và endpoint phía worker; không dựa vào README scaffold cũ nếu có khác biệt.
- Giữ pattern cấu hình hiện tại: Worker URL override qua environment, bindings ở `wrangler.toml`, secret nằm ở Cloudflare hoặc Firebase chứ không hard-code thêm vào app.
- Không commit credential trường học, Firebase token hoặc secret Cloudflare.
- Với refactor MVC, tách theo từng cụm an toàn: `views` trước, rồi `controllers`, rồi `services` và `tests`; tránh đổi đồng loạt toàn bộ app trong một lượt.
- Mỗi lần thay đổi ranh giới module thực sự, cập nhật lại `docs/project-structure.md` hoặc tài liệu liên quan để doc không lệch khỏi code.
- Nếu cần tạo thêm controller mới, chỉ làm khi logic đủ lớn hoặc đủ độc lập; không tạo file controller chỉ để “đủ MVC”.
- Trước khi merge thay đổi kiến trúc, kiểm tra lại tối thiểu các luồng: boot offline, sync trường, auth Firebase, note/task, attachment, weather.
- Với các ngoại lệ kiến trúc đang tồn tại, xem đó là nợ kỹ thuật có chủ đích; không lấy chúng làm precedent để nhân rộng thêm sang module khác.

### Critical Don't-Miss Rules

- Chỉ `personalTask` mới được xóa; event đồng bộ từ trường như `classSchedule` và `exam` chỉ được thêm ghi chú hoặc tệp đính kèm, không được xóa khỏi lịch.
- Khi sync sang tài khoản sinh viên khác, phải xóa `personalEvents` cũ; không carry task cá nhân giữa hai sinh viên.
- Cloud sync là best-effort và phụ thuộc auth; nếu chưa đăng nhập Firebase thì ghi chú local và offline vẫn phải hoạt động bình thường.
- Notification và home widget là best-effort cho nền tảng hỗ trợ; trên web hoặc platform không hỗ trợ phải no-op an toàn.
- Attachment flow phải hỗ trợ đủ ba trạng thái: file local, bytes/base64 và `remoteKey`; không được giả định luôn có filesystem hoặc luôn có mạng.
- Worker phải luôn giữ user scoping bằng Firebase `uid`; không thêm endpoint hoặc query cho phép đọc chéo dữ liệu người dùng.
- Không để refactor MVC làm đổi hành vi người dùng mà không chú ý, nhất là các flow thêm/sửa/xóa task, mở attachment và sync.
- Nếu đang kéo dialog hoặc snackbar ra khỏi controller, phải giữ nguyên message, điều kiện hiển thị và thời điểm hiển thị cho đến khi có quyết định UX khác.
- Không đổi ranh giới module bằng cách đẩy business logic xuống `views`; nếu cần làm mỏng controller thì tách helper hoặc service, không đẩy logic sang widget.
- Không refactor attachment, cache và sync cùng lúc trong một bước lớn nếu chưa có test che chắn, vì đây là các vùng dễ gây mất dữ liệu nhất.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code in the Flutter app or Cloudflare Worker.
- Follow all rules exactly as documented, especially MVC boundaries, local-first behavior, and typed result patterns.
- When in doubt, prefer the more restrictive option and avoid introducing new architectural patterns casually.
- Update this file when new recurring patterns, constraints, or exceptions emerge.

**For Humans:**

- Keep this file lean and focused on rules that agents are likely to miss.
- Update it when the technology stack, auth flow, storage strategy, or module boundaries change.
- Review it periodically and remove rules that become obsolete or too obvious.
- When docs and code diverge, fix the docs and refresh this file to match the real source of truth.

Last Updated: 2026-04-02T22:00:00+07:00
