---
project_name: 'sinhvien-app'
user_name: 'Nguyễn'
date: '2026-04-02T21:44:25.2030433+07:00'
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
rule_count: 73
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

- Flutter app: Dart SDK `^3.11.0`, Flutter Material app, `flutter_localizations`, `flutter_lints ^6.0.0`
- Auth và cloud trên app: `firebase_core ^4.6.0`, `firebase_auth ^6.3.0`, `google_sign_in ^7.2.0`
- Dữ liệu và tích hợp thiết bị: `shared_preferences ^2.5.3`, `flutter_local_notifications ^19.4.2`, `timezone ^0.10.1`, `path_provider ^2.1.5`
- File và media: `file_picker ^10.3.2`, `image_picker ^1.1.2`, `image ^4.5.4`, `pdf ^3.11.3`, `open_filex ^4.7.0`
- Networking: `http ^1.5.0`, Open-Meteo API cho thời tiết, API trường TLU tại `https://sinhvien1.tlu.edu.vn/education`
- Cloudflare Worker: TypeScript `^5.8.3`, `wrangler ^4.11.1`, `jose ^6.0.10`, `@cloudflare/workers-types ^4.20260327.0`, `strict: true`, `compatibility_date = 2026-04-01`
- Lưu trữ cloud: D1 + KV + R2; Flutter app đọc Worker URL từ `String.fromEnvironment('CLOUDFLARE_WORKER_URL')`
- Kiến trúc app trong `lib/`: MVC thực dụng với `views/`, `controllers/`, `models/`, `services/`, `utils/`, `theme/`
- Quy ước refactor mục tiêu: tiếp tục giữ MVC thực dụng cho Flutter, không thêm tầng trung gian mới nếu chưa có nhu cầu rõ ràng
- Ghi chú kiến trúc: code thực tế nhìn chung theo MVC, nhưng vẫn có vài điểm view-driven cục bộ như `grades_page.dart` tự tính GPA và `schedule_page.dart` còn dùng `WeatherService` để format dữ liệu hiển thị

## Critical Implementation Rules

### Language-Specific Rules

- Giữ quy ước hiện tại: file `snake_case`, class/widget `PascalCase`, member private có tiền tố `_`.
- Ưu tiên model typed và `copyWith`; không lan `dynamic` ra ngoài biên parse/integration. Nếu service nhận payload chưa chắc chắn, hãy normalize tại service hoặc mapper trước khi trả về controller.
- Parse JSON theo kiểu phòng thủ như code hiện có: dùng `whereType<Map>()`, `toString()`, `DateTime.tryParse()`, `int.tryParse()`; không giả định shape API ổn định.
- Mọi async flow đụng tới UI phải kiểm tra `context.mounted`; mọi callback muộn trong controller phải kiểm tra thêm `_isDisposed` trước `notifyListeners()` hoặc khi phát side effect.
- Với tác vụ fire-and-forget từ view/controller, dùng `unawaited(...)` như pattern đang có thay vì bỏ trôi `Future`.
- Khi cập nhật state từ kết quả async, luôn gán state tập trung rồi mới `notifyListeners()`; tránh notify nhiều nhịp nhỏ nếu không cần vì dễ làm view rebuild khó đoán.
- Dữ liệu đi qua controller nên ưu tiên immutable update: map/copy danh sách thay vì mutate trực tiếp object đang render.
- Không truyền `BuildContext` xuống `services` hoặc `models`; `BuildContext` chỉ được phép xuất hiện ở `views` và tạm thời ở `controllers` trong các flow UI chưa tách hết.

### Framework-Specific Rules

- Tôn trọng MVC thực dụng của repo: `views` chỉ render và nhận input; `controllers` giữ state UI và điều phối flow; `services` chỉ xử lý kỹ thuật/tích hợp; `utils` phải là hàm thuần.
- Khi refactor theo MVC, ưu tiên kéo UI flow ra khỏi controller theo hướng: view mở dialog/sheet/picker, controller nhận input đã chuẩn hóa và trả về state/result; không đổi sang kiến trúc khác như BLoC/Riverpod/MVVM trong cùng đợt.
- `BuildContext`, `Navigator`, `showDialog`, `showModalBottomSheet`, `ScaffoldMessenger` nên nằm ở `views`; nếu controller hiện còn dùng chúng, xem đó là vùng nợ kỹ thuật cần giảm dần chứ không mở rộng thêm.
- `HomeController` là controller điều phối cấp màn hình cho toàn bộ home shell; không nhét thêm parse API, persistence low-level, hay widget rendering logic vào đây.
- `services` không được giữ state UI, không `notifyListeners()`, và không phụ thuộc widget tree; service chỉ trả dữ liệu typed hoặc ném exception typed.
- `views/home/*` chỉ nên compose widget, bind state, forward callback, và xử lý UI ephemeral state cục bộ; không gọi trực tiếp `SchoolApiService`, `CloudSyncService`, `LocalCacheService`, hay `AuthService`.
- Ngoại lệ hiện có: `SchedulePage` vẫn nhận `WeatherService` để format mô tả/gợi ý thời tiết; xem đây là nợ kiến trúc cục bộ cần giữ ổn định hoặc giảm dần, không phải pattern để nhân rộng sang view khác.
- Tab `grades` hiện vẫn view-driven; chỉ thêm controller riêng khi logic tính toán, lọc, hoặc async flow tăng rõ rệt, không tạo controller cho đủ bộ.
- Với logic tính toán thuần trong view như GPA ở `grades_page.dart`, chỉ giữ tại view khi phạm vi nhỏ và đồng bộ; nếu bắt đầu lặp lại, phình to, hoặc cần test riêng thì chuyển sang controller hoặc `utils`.
- Giữ offline-first boot: app vẫn phải chạy nếu Firebase init thất bại; local cache và weather được load song song; cloud chỉ bổ sung chứ không được chặn trải nghiệm local.
- State UI hiện dùng `ChangeNotifier` + `ListenableBuilder`; khi thêm state mới, cập nhật cùng phong cách này thay vì pha trộn state manager khác.
- Chức năng đa nền tảng phải dùng conditional import/export (`io`, `web`, `stub`) như `attachment_opener` và `http_client_factory`; không viết nhánh runtime làm vỡ compile target.

### Testing Rules

- Trước khi chốt thay đổi, chạy tối thiểu `flutter analyze` và `flutter test`.
- Ưu tiên test theo ranh giới MVC hiện có: widget tests cho `views`, unit tests cho `controllers`, `models`, `services`; tránh test xuyên nhiều tầng nếu không cần.
- Repo hiện có coverage còn mỏng và mới chủ yếu tập trung trong `test/widget_test.dart`; với mọi thay đổi có logic đáng kể, cần bổ sung test đúng ngay tại ranh giới vừa sửa thay vì dựa vào bộ test hiện có.
- Với refactor MVC, luôn thêm hoặc cập nhật test ở ranh giới vừa thay đổi: nếu kéo logic khỏi view sang controller thì controller phải có test riêng cho nhánh đó.
- Widget test nên tập trung vào render, tương tác cơ bản, callback wiring, và trạng thái rỗng/loading/error; không đẩy business logic nặng vào widget test.
- Controller test nên ưu tiên các flow state transition: load cache, đổi tab, chọn ngày, toggle done, merge payload, xử lý success/error từ service.
- Service test nên cô lập tích hợp ngoài bằng mock/stub/fake; không dùng mạng thật, Firebase thật, hay Cloudflare thật trong test thường xuyên.
- Trong repo này, ưu tiên fake subclass đơn giản như `FakeSchoolApiService`, `FakeLocalCacheService`, `FakeCloudSyncService` khi seam đã rõ; không cần đưa thêm mocking framework mới nếu fake hiện có đã đủ.
- Khi cần test service network, tận dụng constructor injection (`http.Client? client`) hoặc seam tương đương để mock thay vì vá global state.
- Với logic parse dữ liệu trường hoặc cloud payload, thêm test cho dữ liệu thiếu field, sai kiểu, hoặc null để giữ parsing phòng thủ.
- Sau refactor lớn ở `HomeController`, cần có ít nhất một test bảo vệ các quy tắc không được phá: chỉ `personalTask` mới được xóa, sync tài khoản khác phải xóa `personalEvents`, cloud lỗi không làm mất local data.
- Nếu sau này tách thêm test file riêng cho controller/service, giữ naming và phạm vi test rõ ràng; không tiếp tục nhồi toàn bộ test mới vào `widget_test.dart` khi suite bắt đầu lớn lên.

### Code Quality & Style Rules

- Giữ UI theo Material 3 theme có sẵn và copy tiếng Việt là mặc định; chỉ thêm tiếng Anh khi thật sự liên quan tới localization support.
- Sau mọi thao tác merge/persist event, luôn sort theo `start` trước khi render, sync widget, hay reschedule notification.
- Muốn lưu payload học tập thì đi qua `LocalCachePayload` + đường persist tập trung; không tạo đường lưu riêng vào `SharedPreferences`, ngoại trừ dữ liệu widget trong `WidgetSyncService`.
- Dùng helper sẵn có cho date/event formatting và calendar math (`HomeCalendarUtils`, helper trong service/model); tránh nhân bản logic thời gian ở nhiều file.
- Bắt lỗi theo kiểu degrade gracefully: service ném exception typed, controller đổi thành state/result/thông báo thân thiện; lỗi weather/cloud/Firebase không được làm app chết hoặc mất local data.
- Mỗi file nên có một trách nhiệm chính theo đúng tầng MVC; nếu một file vừa parse dữ liệu, vừa giữ state, vừa dựng UI thì cần tách lại.
- Không thêm helper “tiện tay” vào `views` nếu logic đó có thể tái sử dụng hoặc kiểm thử độc lập; chuyển sang `controller`, `service`, hoặc `utils` tùy bản chất.
- Nếu controller bắt đầu phình to, ưu tiên tách theo use case hoặc phối hợp qua service/handler nhỏ, thay vì đẩy ngược logic xuống widget.
- Tên hàm trong controller nên thể hiện ý định người dùng hoặc flow nghiệp vụ như `syncSchoolData`, `saveTaskEdits`, `loadWeather`; tránh tên quá kỹ thuật kiểu `doProcess`, `handleStuff`.
- Khi refactor MVC, ưu tiên đổi nhỏ và giữ hành vi cũ; không trộn refactor kiến trúc với thay đổi UI lớn trong cùng một commit.
- Với logic hiển thị thuần và nhỏ trong view như đếm số sự kiện, format nhãn, hay tính GPA cục bộ, chỉ giữ tại view khi không có nhu cầu tái sử dụng hoặc test riêng; nếu logic bắt đầu lan sang nhiều widget thì phải kéo ra `utils` hoặc controller.

### Development Workflow Rules

- `docs/project-structure.md` là tài liệu kiến trúc mô tả đúng tổ chức Flutter MVC hiện tại; dùng nó làm source of truth cho ranh giới module trong app.
- Khi tài liệu và code mâu thuẫn, ưu tiên code đang chạy đúng; sau đó cập nhật lại doc và `project-context.md` cho khớp.
- `cloudflare-worker/src/index.ts` mới là source of truth cho auth và endpoint; không dựa vào README scaffold cũ nếu có khác biệt.
- Giữ pattern cấu hình hiện tại: Worker URL override qua environment, bindings ở `wrangler.toml`, secret nằm ở Cloudflare/Firebase chứ không hard-code thêm vào app.
- Không commit credential trường học, Firebase token, hay secret Cloudflare; app chỉ được gửi Firebase Bearer token tới Worker và Worker mới quyết định truy cập dữ liệu theo `uid`.
- Với refactor MVC, nên tách theo từng cụm an toàn: `views` trước, rồi `controllers`, rồi `services`/tests; tránh đổi đồng loạt toàn bộ app trong một lượt.
- Mỗi lần refactor một flow lớn, cập nhật lại `docs/project-structure.md` hoặc tài liệu liên quan nếu ranh giới module đã thay đổi thật sự.
- Nếu cần tạo thêm controller mới, phải chứng minh được logic đã đủ lớn hoặc đủ độc lập; không tạo file/controller chỉ để “đủ MVC”.
- Trước khi merge thay đổi kiến trúc, kiểm tra lại ít nhất các luồng: boot offline, sync trường, auth Firebase, note/task, attachment, weather.
- Với các ngoại lệ kiến trúc đang tồn tại như `SchedulePage` dùng `WeatherService` hoặc `grades_page.dart` giữ logic GPA, nếu chưa refactor ngay thì phải coi đó là ngoại lệ có chủ đích và tránh nhân rộng thêm ở module khác.

### Critical Don't-Miss Rules

- Chỉ `personalTask` mới được xóa; event đồng bộ từ trường (`classSchedule`, `exam`) chỉ được thêm ghi chú/tệp đính kèm, không được cho xóa khỏi lịch.
- Khi sync sang tài khoản sinh viên khác, phải xóa `personalEvents` cũ như logic `_payloadFromSnapshot`; không carry task cá nhân giữa hai sinh viên.
- Cloud sync là best-effort và phụ thuộc auth: nếu chưa đăng nhập Firebase thì ghi chú local/offline vẫn phải hoạt động bình thường.
- Notification và home widget hiện chỉ là best-effort cho nền tảng hỗ trợ, chủ yếu Android; web hoặc platform không hỗ trợ phải no-op an toàn.
- Attachment flow phải hỗ trợ đủ ba trạng thái: file local, bytes/base64, và `remoteKey`; không được giả định luôn có filesystem hoặc luôn có mạng.
- Worker phải luôn giữ user scoping bằng Firebase `uid` cho notes/tasks/cache/attachments; không thêm endpoint hay query nào cho phép đọc chéo dữ liệu người dùng.
- Không để refactor MVC làm thay đổi hành vi người dùng mà không chủ ý, nhất là các flow thêm/sửa/xóa task, mở attachment, và sync.
- Nếu đang kéo `showDialog` hoặc `SnackBar` ra khỏi controller, phải giữ nguyên message, điều kiện hiển thị, và thời điểm hiển thị cho đến khi có quyết định UX khác.
- Không đổi ranh giới module bằng cách chuyển business logic xuống `views`; nếu cần đơn giản hóa controller, hãy tách helper/service chứ không đẩy logic sang widget.
- Không refactor attachment, cache, và sync cùng lúc trong một bước nếu chưa có test che chắn, vì đây là ba vùng dễ gây mất dữ liệu nhất.
- Không lấy việc repo “đã là MVC” làm lý do bỏ qua các ngoại lệ đang tồn tại; mọi thay đổi mới phải giảm hoặc cô lập ngoại lệ, không được dựa vào đó để hợp thức hóa việc cho view gọi thêm service trực tiếp.

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

Last Updated: 2026-04-02T21:44:25.2030433+07:00
