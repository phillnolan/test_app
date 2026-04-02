# Kiến trúc tích hợp

**Ngày quét:** 2026-04-02T14:13:05+07:00

## Tổng quan

Repo có hai part chính nhưng tương tác với nhiều hệ ngoài:

- `mobile-app`
- `worker-api`
- Firebase Auth
- TLU education API
- Open-Meteo
- Cloudflare D1 / KV / R2
- Android launcher widget

## Sơ đồ luồng mức cao

```text
Người dùng
  ↓
mobile-app (Flutter)
  ├─ gọi trực tiếp TLU education API để lấy dữ liệu trường
  ├─ gọi Open-Meteo để lấy thời tiết
  ├─ lấy Firebase ID token khi người dùng đăng nhập
  ├─ gọi worker-api để lưu note/task/snapshot/attachment
  ├─ lưu cache local bằng SharedPreferences
  └─ cập nhật notification + Android widget

worker-api (Cloudflare Worker)
  ├─ verify Firebase token
  ├─ ghi metadata vào D1
  ├─ ghi snapshot vào KV (+ log xuống D1)
  └─ lưu file vào R2
```

## Tích hợp 1: Đồng bộ dữ liệu trường

1. Người dùng nhập tài khoản cổng sinh viên.
2. App gọi `POST /oauth/token`.
3. Access token được dùng để gọi profile, marks, timetable, exams, curriculum.
4. Kết quả được chuẩn hóa thành `SchoolSyncSnapshot`.
5. `HomeController` chuyển snapshot thành `LocalCachePayload`.
6. Payload được lưu local và phản ánh lên UI/tab lịch/điểm.

## Tích hợp 2: Đồng bộ cloud

1. Người dùng đăng nhập Google hoặc email/password.
2. App lấy Firebase ID token.
3. `CloudSyncService` thêm header `Authorization: Bearer ...`.
4. Worker verify token qua Google JWKS.
5. Worker ghi dữ liệu theo `firebase_uid`.

## Tích hợp 3: Snapshot và khôi phục trạng thái

1. App tạo payload đã cập nhật.
2. `CloudSyncService.saveSyncCache()` gửi `snapshotKey=dashboard`.
3. Worker ghi JSON vào KV với TTL và lưu một record vào `sync_snapshots`.
4. Khi auth state chuyển sang signed-in, app đọc lại `GET /sync-cache?key=dashboard`.

## Tích hợp 4: Attachment pipeline

1. User tạo/chọn attachment trong app.
2. `AttachmentStorageService` lưu file về local documents directory.
3. `CloudSyncService.uploadAttachment()` gửi raw bytes qua Worker.
4. Worker sinh `objectKey`, lưu file vào R2, lưu metadata vào D1.
5. App giữ `remoteKey` để tải lại về sau.

## Tích hợp 5: Notification và home widget

1. Mỗi lần payload đổi, app reschedule notification cho event trong 14 ngày tới.
2. App ghi summary lịch hôm nay vào `SharedPreferences`.
3. `WidgetSyncService` gọi `MethodChannel`.
4. `MainActivity` trigger `TodayScheduleWidgetProvider.updateAll()`.

## Tích hợp 6: Thời tiết

1. `HomeController.initialize()` gọi `reloadWeather()`.
2. `WeatherService` lấy forecast 7 ngày ở Hà Nội.
3. `SchedulePage` render thẻ thời tiết tương ứng ngày đang chọn.

## Điểm cần chú ý

- Luồng school sync và auth/cloud sync là hai luồng độc lập.
- Một số tài liệu cũ trong repo mô tả Worker như trung gian lấy dữ liệu trường; mã hiện tại không làm vậy.

---

_Generated using BMAD Method `document-project` workflow_
