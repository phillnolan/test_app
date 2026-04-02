# Data Models - mobile-app

**Part ID:** `mobile-app`

## Tổng quan

Phần mobile không có cơ sở dữ liệu cục bộ kiểu SQLite; mô hình dữ liệu chính được serialize vào `SharedPreferences` dưới dạng `LocalCachePayload`. Các model đều nằm trong `lib/models/`.

## Aggregate chính

### `LocalCachePayload`

Đây là aggregate state quan trọng nhất được lưu local:

- `profile`
- `grades`
- `curriculumSubjects`
- `curriculumRawItems`
- `syncedEvents`
- `personalEvents`
- `lastSyncedAt`

## Model lõi

### `StudentProfile`

- thông tin sinh viên lấy từ API trường

### `GradeItem`

- mã môn
- tên môn
- tín chỉ
- điểm hệ 10
- điểm hệ 4
- điểm chữ

### `ProgramSubject`

- mã môn
- tên môn
- khối kiến thức
- học kỳ
- số tín chỉ
- logic suy diễn cho tự chọn, đồ án, quốc phòng, thể chất, chuẩn đầu ra

### `StudentEvent`

- `id`
- `title`
- `start`, `end`
- `type`
- `color`
- `subtitle`
- `location`
- `note`
- `referenceCode`
- `attachments`
- `isDone`

### `EventAttachment`

- metadata cơ bản
- đường dẫn local
- `bytesBase64`
- `remoteKey`

### `SchoolSyncSnapshot`

- gom toàn bộ dữ liệu trả về từ một lần sync cổng trường

### `WeatherForecast`

- dữ liệu forecast 7 ngày cho Hà Nội

## Serialize/deserialize

- Hầu hết model có `toJson()` và `fromJson()`
- `DateTime` serialize thành ISO string
- `Color` serialize thành ARGB int

## Nguồn dữ liệu

- từ API trường: profile, grades, curriculum, lịch học, lịch thi
- từ người dùng: personal task, note, attachments, `isDone`
- từ cloud: snapshot cùng cấu trúc `LocalCachePayload`

## Nhận xét

- Mô hình dữ liệu khá sạch và đủ dùng cho local-first sync.
- `curriculumRawItems` giữ bản raw JSON từ API, hữu ích cho debug nhưng làm payload lớn hơn.

---

_Generated using BMAD Method `document-project` workflow_
