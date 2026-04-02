# Development Guide - mobile-app

**Part ID:** `mobile-app`

## Mục tiêu

Hướng dẫn này giúp chạy, debug và kiểm tra ứng dụng Flutter ở thư mục gốc repo.

## Điều kiện cần

- Flutter SDK tương thích Dart `^3.11.0`
- Android Studio hoặc VS Code với Flutter plugin
- Android emulator hoặc thiết bị Android thật
- Node.js chỉ cần nếu bạn cũng chạy `worker-api`

## Setup

```bash
flutter pub get
```

Nếu cần kiểm tra nền tảng:

```bash
flutter doctor
```

## Chạy local

### Android

```bash
flutter run -d android
```

### Web

```bash
flutter run -d chrome
```

### Mặc định

```bash
flutter run
```

## Build và kiểm tra

```bash
flutter analyze
flutter test
flutter build apk
flutter build web
```

## Chạy với Worker khác

```bash
flutter run --dart-define=CLOUDFLARE_WORKER_URL=https://your-worker.example.workers.dev
```

## Điểm cần chú ý khi sửa mã

- `HomeController` là trung tâm orchestration, nên mọi thay đổi đồng bộ/event dễ ảnh hưởng chéo.
- `SchoolApiService` chứa logic parse API trường; thay đổi field map cần test thật kỹ.
- `GoalPlannerSection` có nhiều logic tính toán hơn các màn hình khác.
- `image_attachment_editor.dart` là file UI lớn và tương đối độc lập.

## Rủi ro hiện tại

- Firebase chỉ được cấu hình cho Android và Web, chưa có iOS/macOS/windows/linux.
- Test coverage còn mỏng.
- Worker URL mặc định đang hard-code nếu không dùng `dart-define`.

---

_Generated using BMAD Method `document-project` workflow_
