# sinhvien-app - Tổng quan dự án

**Ngày quét:** 2026-04-02T14:13:05+07:00  
**Loại repo:** Monorepo 2 phần  
**Loại dự án:** Mobile client + backend serverless  
**Mẫu kiến trúc:** Flutter MVC thực dụng + Cloudflare Worker REST API

## Tóm tắt điều hành

`sinhvien-app` là ứng dụng hỗ trợ sinh viên theo dõi lịch học, lịch thi, bảng điểm, chương trình đào tạo và ghi chú cá nhân trong một giao diện thống nhất. Repo hiện gồm hai phần tích hợp chặt chẽ:

- Ứng dụng Flutter ở thư mục gốc, chạy chính trên Android và có cấu hình web.
- Cloudflare Worker trong `cloudflare-worker/`, dùng để đồng bộ ghi chú, task, tệp đính kèm và snapshot dữ liệu qua D1, KV, R2.

Điểm mạnh kiến trúc hiện tại là trải nghiệm local-first: dữ liệu trường được tải từ cổng sinh viên, lưu cache cục bộ bằng `SharedPreferences`, sau đó các phần dữ liệu cá nhân được đồng bộ lên cloud khi người dùng đăng nhập Firebase. Điều này cho phép app vẫn dùng được khi offline, trong khi vẫn có khả năng khôi phục ghi chú và tệp giữa các thiết bị.

## Phân loại dự án

- **Repository type:** Monorepo
- **Các part chính:** `mobile-app`, `worker-api`
- **Ngôn ngữ chính:** Dart, TypeScript
- **Ngôn ngữ phụ:** Kotlin, SQL, JSON, TOML
- **Phụ thuộc hạ tầng:** Firebase Auth, Cloudflare Worker, D1, KV, R2, Open-Meteo, API cổng sinh viên TLU

## Cấu trúc nhiều phần

### 1. mobile-app

- **Loại:** `mobile`
- **Vị trí:** `.`
- **Mục đích:** Ứng dụng Flutter cho sinh viên xem lịch, điểm, đồng bộ dữ liệu trường, quản lý ghi chú và tệp đính kèm
- **Stack:** Flutter 3 / Dart 3.11, Firebase Core/Auth, Google Sign-In, local notifications, SharedPreferences

### 2. worker-api

- **Loại:** `backend`
- **Vị trí:** `cloudflare-worker/`
- **Mục đích:** API serverless xác thực Firebase token và lưu dữ liệu người dùng vào Cloudflare
- **Stack:** Cloudflare Worker, TypeScript, `jose`, D1, KV, R2, Wrangler

## Cách các phần tích hợp với nhau

1. Người dùng dùng tab `Đồng bộ` để nhập tài khoản cổng sinh viên.
2. `SchoolApiService` gọi trực tiếp API trường, chuẩn hóa dữ liệu thành `SchoolSyncSnapshot`.
3. `HomeController` ghi payload vào cache cục bộ, cập nhật notification và Android widget.
4. Khi đã đăng nhập Firebase, `CloudSyncService` lấy Firebase ID token và gọi Worker.
5. Worker xác thực token bằng JWKS của Google, sau đó:
   - ghi note và personal task vào D1,
   - ghi snapshot dashboard vào KV và đồng thời log sang D1,
   - upload/download tệp đính kèm qua R2.

## Tóm tắt stack công nghệ

### mobile-app

| Nhóm | Công nghệ | Ghi chú |
| --- | --- | --- |
| UI | Flutter Material 3 | `lib/app.dart`, `lib/theme/app_theme.dart` |
| State/UI flow | `ChangeNotifier` + controller | `HomeController`, `AccountAuthController` |
| Auth | Firebase Auth, Google Sign-In | Đăng nhập cloud là tùy chọn |
| Local storage | SharedPreferences | Lưu `LocalCachePayload` |
| Notifications | `flutter_local_notifications`, `timezone` | Chỉ chạy Android |
| External APIs | TLU education API, Open-Meteo | Đồng bộ dữ liệu trường và thời tiết |

### worker-api

| Nhóm | Công nghệ | Ghi chú |
| --- | --- | --- |
| Runtime | Cloudflare Worker | `src/index.ts` |
| Auth | `jose` + Firebase ID token verify | Xác thực qua Google JWKS |
| Database | Cloudflare D1 | `users`, `notes`, `attachments`, `personal_tasks`, `sync_snapshots` |
| Cache | Cloudflare KV | Lưu snapshot dashboard theo TTL |
| File storage | Cloudflare R2 | Lưu PDF, DOC, ảnh đính kèm |
| Infra config | Wrangler | `wrangler.toml` |

## Chức năng nổi bật

- Lịch học, lịch thi và việc cá nhân hiển thị trên cùng một lịch ngày.
- Ghi chú và đính kèm tệp trực tiếp trên từng sự kiện.
- Xem bảng điểm và chương trình đào tạo.
- Lập kế hoạch GPA mục tiêu và gợi ý học lại/chọn môn chắc A.
- Cache dữ liệu để dùng offline.
- Đồng bộ cloud cho note, task, attachments và snapshot.
- Notification cục bộ và Android home widget cho lịch hôm nay.

## Điểm nhấn kiến trúc

- `HomeController` là điểm điều phối trung tâm giữa UI, local cache, sync trường, sync cloud, weather, notification và widget.
- App ưu tiên local-first: cloud failure không chặn trải nghiệm cơ bản.
- Worker tách biệt hẳn lưu trữ cloud khỏi client, tránh để app nói chuyện trực tiếp với D1/KV/R2.
- Repo đang có dấu vết tài liệu cũ về một scraper/backend khác; mã hiện tại phản ánh mô hình gọi trực tiếp API trường từ app, không phải từ Worker.

## Tổng quan phát triển

### Điều kiện cần

- Flutter SDK tương thích Dart `^3.11.0`
- Android Studio hoặc VS Code
- Node.js để chạy `cloudflare-worker`
- Tài nguyên Cloudflare đã tạo sẵn nếu muốn test cloud thật

### Khởi động nhanh

- Mobile app: `flutter pub get` rồi `flutter run`
- Worker: `cd cloudflare-worker`, `npm install`, `npm run dev`

### Lệnh chính

#### mobile-app

- **Install:** `flutter pub get`
- **Dev:** `flutter run`
- **Build web:** `flutter run -d chrome`
- **Test:** `flutter test`

#### worker-api

- **Install:** `npm install`
- **Dev:** `npm run dev`
- **Deploy:** `npm run deploy`

## Tóm tắt cấu trúc repo

Repo đặt app Flutter ở thư mục gốc để thuận tiện cho Android/Web build, còn backend cloud tách riêng trong `cloudflare-worker/`. `docs/` hiện chứa cả tài liệu mới được quét và một số tài liệu lịch sử/đề xuất cũ. Các thư mục sinh build như `build/`, `.dart_tool/`, `cloudflare-worker/node_modules/` không phải phần lõi của kiến trúc.

## Bản đồ tài liệu

- [index.md](./index.md) - Điểm vào chính cho AI và người mới
- [architecture-mobile-app.md](./architecture-mobile-app.md) - Kiến trúc app Flutter
- [architecture-worker-api.md](./architecture-worker-api.md) - Kiến trúc Worker
- [integration-architecture.md](./integration-architecture.md) - Luồng giao tiếp giữa các part
- [source-tree-analysis.md](./source-tree-analysis.md) - Cây thư mục có chú giải
- [development-guide-mobile-app.md](./development-guide-mobile-app.md) - Hướng dẫn phát triển app
- [development-guide-worker-api.md](./development-guide-worker-api.md) - Hướng dẫn phát triển Worker

---

_Generated using BMAD Method `document-project` workflow_
