# API Contracts - worker-api

**Part ID:** `worker-api`

## Quy ước chung

- **Content type response:** `application/json; charset=utf-8`
- **Auth:** tất cả route trừ `/health` yêu cầu `Authorization: Bearer <firebase-id-token>`
- **CORS:** bật cho `GET,POST,OPTIONS`

## `GET /health`

- không yêu cầu auth

```json
{
  "ok": true,
  "data": {
    "status": "healthy",
    "env": "development"
  }
}
```

## `GET /notes`

- trả danh sách note của user hiện tại

## `POST /notes`

```json
{
  "id": "note-id",
  "eventId": "event-id",
  "eventType": "classSchedule",
  "content": "Ghi chú"
}
```

## `POST /tasks`

```json
{
  "id": "task-id",
  "title": "Làm bài tập",
  "note": "Xem lại chương 3",
  "startAt": "2026-04-02T08:00:00.000Z",
  "endAt": "2026-04-02T09:00:00.000Z",
  "isDone": false
}
```

## `POST /sync-cache`

```json
{
  "snapshotKey": "dashboard",
  "payload": {
    "profile": null,
    "grades": [],
    "curriculumSubjects": [],
    "curriculumRawItems": [],
    "syncedEvents": [],
    "personalEvents": [],
    "lastSyncedAt": "2026-04-02T07:00:00.000Z"
  },
  "ttlSeconds": 21600
}
```

## `GET /sync-cache?key=<snapshotKey>`

- đọc snapshot đã lưu của user hiện tại

## `POST /attachments/upload`

- headers bắt buộc:
  - `authorization`
  - `x-file-name`
  - `x-event-id`
  - `content-type`
- body là raw bytes

## `GET /attachments/download?key=<objectKey>`

- trả raw bytes của attachment nếu thuộc user hiện tại

## Lỗi chung

### `401`

```json
{
  "ok": false,
  "error": "Invalid Firebase token."
}
```

### `404`

```json
{
  "ok": false,
  "error": "Not found."
}
```

---

_Generated using BMAD Method `document-project` workflow_
