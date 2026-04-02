# API Contracts - mobile-app

**Part ID:** `mobile-app`

## Tổng quan

Ứng dụng Flutter đóng vai trò client của 3 nhóm API:

1. API cổng sinh viên TLU
2. API Cloudflare Worker cho dữ liệu cá nhân/cloud sync
3. API Open-Meteo cho thời tiết

## 1. Cổng sinh viên TLU

**Base host:** `https://sinhvien1.tlu.edu.vn/education`

### `POST /oauth/token`

- **Mục đích:** lấy access token
- **Body:**

```json
{
  "client_id": "education_client",
  "grant_type": "password",
  "username": "<student_username>",
  "password": "<student_password>",
  "client_secret": "password"
}
```

### `GET /api/student/getstudentbylogin`

- lấy hồ sơ sinh viên và program ids

### `GET /api/studentsubjectmark/getListMarkDetailStudent`

- lấy bảng điểm

### `GET /api/StudentCourseSubject/studentLoginUser/14`

- lấy lịch học

### `GET /api/programsubject/tree/{programId}/1/10000`

- lấy chương trình đào tạo

### `GET /api/semestersubjectexamroom/getListRoomByStudentByLoginUser/{routeId}/{semesterId}/1`

- lấy lịch thi
- app hiện dùng `routeId = 14`, `semesterId = 66`

## 2. Cloudflare Worker

**Base URL mặc định:** `https://sinhvien-worker.nkocpk99012.workers.dev`

**Auth:** `Authorization: Bearer <firebase-id-token>`

### `POST /notes`

```json
{
  "id": "event-id",
  "eventId": "event-id",
  "eventType": "classSchedule|exam|personalTask",
  "content": "Ghi chú..."
}
```

### `POST /tasks`

```json
{
  "id": "task-id",
  "title": "Làm bài tập",
  "note": "Chi tiết",
  "startAt": "2026-04-02T08:00:00.000Z",
  "endAt": "2026-04-02T09:00:00.000Z",
  "isDone": false
}
```

### `POST /sync-cache`

```json
{
  "snapshotKey": "dashboard",
  "payload": { "...": "LocalCachePayload JSON" },
  "ttlSeconds": 21600
}
```

### `GET /sync-cache?key=dashboard`

- khôi phục state cloud về app

### `POST /attachments/upload`

- headers bổ sung: `x-file-name`, `x-event-id`, `content-type`
- body là raw bytes

### `GET /attachments/download?key=<remoteKey>`

- tải lại attachment từ R2 qua Worker

## 3. Open-Meteo

### Forecast 7 ngày

`GET https://api.open-meteo.com/v1/forecast?...`

- hiện đang gọi theo tọa độ Hà Nội
- dùng để tạo `WeatherForecast`

## Ghi chú hành vi client

- Worker chỉ được gọi khi đã có Firebase user.
- Nếu Worker lỗi, app vẫn giữ local payload.
- School API có retry logic cho request GET và fetch exams.

---

_Generated using BMAD Method `document-project` workflow_
