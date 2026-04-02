# Cấu trúc thư mục theo MVC

Tài liệu này mô tả cấu trúc hiện tại của thư mục `lib/` sau khi chuyển app sang mô hình MVC.

## Cây thư mục hiện tại

```text
lib/
├── app.dart
├── firebase_options.dart
├── main.dart
├── controllers/
│   ├── account_auth_controller.dart
│   └── home_controller.dart
├── models/
│   ├── event_attachment.dart
│   ├── grade_item.dart
│   ├── program_subject.dart
│   ├── school_sync_snapshot.dart
│   ├── student_event.dart
│   ├── student_profile.dart
│   └── weather_forecast.dart
├── services/
│   ├── attachment_opener.dart
│   ├── attachment_opener_io.dart
│   ├── attachment_opener_stub.dart
│   ├── attachment_opener_web.dart
│   ├── attachment_storage_service.dart
│   ├── auth_service.dart
│   ├── cloud_sync_service.dart
│   ├── file_bytes_reader_io.dart
│   ├── file_bytes_reader_stub.dart
│   ├── http_client_factory.dart
│   ├── http_client_factory_io.dart
│   ├── http_client_factory_stub.dart
│   ├── http_client_factory_web.dart
│   ├── local_cache_service.dart
│   ├── notification_service.dart
│   ├── school_api_service.dart
│   ├── weather_service.dart
│   └── widget_sync_service.dart
├── theme/
│   └── app_theme.dart
├── utils/
│   └── home_calendar_utils.dart
└── views/
    ├── grades/
    │   ├── grades_page.dart
    │   └── widgets/
    │       ├── curriculum_subjects_section.dart
    │       └── goal_planner_section.dart
    └── home/
        ├── home_shell.dart
        ├── image_attachment_editor.dart
        ├── pages/
        │   ├── account_page.dart
        │   ├── schedule_page.dart
        │   └── sync_page.dart
        └── widgets/
            ├── attachment_editing_helpers.dart
            ├── home_common_widgets.dart
            ├── home_dialogs.dart
            ├── home_editors.dart
            └── home_sheet_models.dart
```

## Ý tưởng tổ chức

Mô hình hiện tại đi theo hướng:

- `models`: dữ liệu và cấu trúc object
- `views`: toàn bộ UI
- `controllers`: state và luồng điều phối từ UI sang service

Ngoài ra còn có:

- `services`: tầng hạ tầng và tích hợp ngoài
- `utils`: hàm thuần hỗ trợ
- `theme`: cấu hình giao diện dùng chung

Đây là MVC thực dụng cho Flutter, nghĩa là:

- View không tự ôm business logic nặng.
- Controller giữ state UI và điều phối flow.
- Model giữ dữ liệu cốt lõi.
- Service đứng dưới controller như tầng hỗ trợ kỹ thuật.

## Luồng khởi động app

### `main.dart`

Chịu trách nhiệm:

- khởi tạo Flutter binding
- khởi tạo Firebase
- khởi tạo `NotificationService`
- chạy `StudentPlannerApp`

### `app.dart`

Chịu trách nhiệm:

- cấu hình `MaterialApp`
- gắn theme
- đặt locale
- chọn màn hình gốc là `HomeShell`

Luồng vào app hiện tại là:

`main.dart` -> `app.dart` -> `views/home/home_shell.dart`

## Phần `controllers`

### `account_auth_controller.dart`

Vai trò:

- bọc `AuthService`
- xử lý đăng nhập email
- xử lý đăng nhập Google
- xử lý đăng xuất
- lắng nghe auth state

Lý do tồn tại:

- tách auth flow khỏi view
- tránh để `AccountPage` gọi trực tiếp vào Firebase/AuthService

### `home_controller.dart`

Đây là controller trung tâm của app hiện tại.

Vai trò:

- giữ state cho `HomeShell`
- điều phối 4 tab: lịch, điểm, đồng bộ, tài khoản
- load local cache
- đồng bộ dữ liệu từ cổng trường
- đồng bộ cloud
- load thời tiết
- thêm/sửa/xóa việc cá nhân
- xử lý attachment
- cập nhật notification và widget

State chính đang nằm ở đây:

- `selectedDate`
- `payload`
- `weatherForecast`
- `isSyncing`
- `isLoadingLocalCache`
- `isLoadingWeather`
- `showSyncReminder`
- `currentTab`
- `signedInUser`

Ý nghĩa kiến trúc:

- `home_controller.dart` là cầu nối chính giữa `views/home/*` và `services/*`
- thay vì tách thêm `view model` hay `application layer`, controller này ôm luôn state + flow để cấu trúc bớt rối

## Phần `models`

Thư mục này chứa dữ liệu cốt lõi dùng chung toàn app.

### `event_attachment.dart`

- mô tả tệp đính kèm

### `grade_item.dart`

- mô tả một dòng điểm của sinh viên

### `program_subject.dart`

- mô tả một môn trong chương trình đào tạo

### `school_sync_snapshot.dart`

- gói dữ liệu trả về sau một lần sync từ cổng trường

### `student_event.dart`

- mô tả event trong lịch
- gồm lịch học, lịch thi, việc cá nhân

### `student_profile.dart`

- mô tả thông tin tài khoản sinh viên lấy từ hệ thống trường

### `weather_forecast.dart`

- mô tả dữ liệu dự báo thời tiết

## Phần `views`

Toàn bộ UI hiện nằm ở đây.

## `views/home`

Đây là khu vực UI lớn nhất.

### `home_shell.dart`

Vai trò:

- entry view chính của app
- bind `HomeController` với UI
- dựng `IndexedStack`
- nối callback sang controller

File này nên giữ mỏng:

- chỉ build UI
- không chứa logic sync/cache/business nặng

### `image_attachment_editor.dart`

Vai trò:

- màn hình chỉnh sửa ảnh attachment
- crop, vẽ, thêm chữ, xuất lại ảnh

### `pages/`

#### `account_page.dart`

- UI tab tài khoản
- hiển thị auth state
- nút đăng nhập/đăng xuất

#### `schedule_page.dart`

- UI tab lịch
- hero card
- weather card
- day strip
- danh sách event trong ngày

#### `sync_page.dart`

- UI tab đồng bộ
- hiển thị thông tin profile sau khi sync
- nút đồng bộ
- metric về dữ liệu đã có

### `widgets/`

#### `attachment_editing_helpers.dart`

- helper cho chọn file, scan tài liệu, chuyển ảnh sang PDF, mở editor ảnh

#### `home_common_widgets.dart`

- widget dùng chung trong nhóm home
- ví dụ empty state, placeholder info, desktop scroll behavior

#### `home_dialogs.dart`

- dialog và sheet nhẹ
- ví dụ month picker, sync credentials, email auth

#### `home_editors.dart`

- editor cho note/task

#### `home_sheet_models.dart`

- model trả về từ dialog/sheet
- ví dụ `CredentialsResult`, `TaskEditorResult`, `NoteEditorResult`

## `views/grades`

Khu vực UI cho tab điểm.

### `grades_page.dart`

Vai trò:

- view chính của tab điểm
- hiển thị GPA
- hiển thị danh sách điểm
- ghép các widget phân tích học tập

### `widgets/curriculum_subjects_section.dart`

Vai trò:

- hiển thị chương trình đào tạo
- nhóm môn và đánh dấu tiến độ

### `widgets/goal_planner_section.dart`

Vai trò:

- tính lộ trình GPA mục tiêu
- gợi ý học lại
- chọn môn chắc A

Nhận xét:

- Phần `grades` hiện thiên về view nhiều hơn controller riêng
- Điều này vẫn chấp nhận được vì logic của tab điểm chưa cần controller tách riêng
- Nếu sau này phần phân tích GPA phình to thêm, có thể bổ sung `grades_controller.dart`

## Phần `services`

Đây là tầng hạ tầng, tích hợp ngoài và xử lý kỹ thuật.

### Nhóm auth

- `auth_service.dart`

### Nhóm sync, API, cache

- `school_api_service.dart`
- `cloud_sync_service.dart`
- `local_cache_service.dart`

### Nhóm attachment, file, mở tài liệu

- `attachment_storage_service.dart`
- `attachment_opener.dart`
- `attachment_opener_io.dart`
- `attachment_opener_stub.dart`
- `attachment_opener_web.dart`
- `file_bytes_reader_io.dart`
- `file_bytes_reader_stub.dart`

### Nhóm HTTP đa nền tảng

- `http_client_factory.dart`
- `http_client_factory_io.dart`
- `http_client_factory_stub.dart`
- `http_client_factory_web.dart`

### Nhóm hệ thống thiết bị

- `notification_service.dart`
- `widget_sync_service.dart`

### Nhóm dữ liệu phụ trợ

- `weather_service.dart`

Lưu ý:

- `services` không phải controller
- service chỉ làm việc chuyên môn kỹ thuật, controller mới là nơi điều phối

## Phần `utils`

### `home_calendar_utils.dart`

Vai trò:

- helper thuần cho lịch
- format ngày giờ
- map index sang date
- tính indicator cho lịch
- so sánh ngày

Lý do để ở `utils`:

- đây là logic thuần
- không cần state
- không nên nằm trong view hay service

## Phần `theme`

### `app_theme.dart`

Vai trò:

- định nghĩa theme chung cho toàn app

## Quan hệ phụ thuộc chính

### Luồng Home

`views/home/*`
-> `controllers/home_controller.dart`
-> `controllers/account_auth_controller.dart` hoặc `services/*`
-> `models/*`

### Luồng Grades

`views/grades/*`
-> `models/*`

Hiện tại tab điểm chưa có controller riêng.

## Vì sao cấu trúc này đỡ rối hơn bản cũ

So với cấu trúc trước:

- không còn `features/home/application/presentation/view_model`
- không còn phải phân biệt `view model` với `controller` cho cùng một màn
- nhìn cây thư mục là thấy ngay:
  - UI ở đâu
  - controller ở đâu
  - data ở đâu

Người mới vào repo thường chỉ cần nhớ:

1. `views/` là nơi render
2. `controllers/` là nơi điều phối
3. `models/` là dữ liệu
4. `services/` là hạ tầng

## Hướng mở rộng tiếp theo

Nếu app lớn hơn, có thể mở rộng MVC như sau:

- thêm `grades_controller.dart` khi tab điểm có nhiều logic hơn
- thêm `sync_controller.dart` nếu phần đồng bộ tách thành module lớn riêng
- chuyển các helper dùng chung nhiều nơi từ `utils/` sang nhóm `core/` nếu cần

Ở quy mô hiện tại, cấu trúc này là cân bằng giữa:

- dễ đọc
- đúng MVC
- không quá nhiều tầng
