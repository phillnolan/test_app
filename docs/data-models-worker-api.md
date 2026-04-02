# Data Models - worker-api

**Part ID:** `worker-api`

## Tổng quan

Worker dùng ba lớp dữ liệu:

- **D1** cho metadata và dữ liệu quan hệ
- **KV** cho snapshot JSON truy cập nhanh
- **R2** cho tệp binary

## Schema D1

### `users`

- `firebase_uid` là khóa logic chính
- lưu `email`, `display_name`, timestamp

### `notes`

- lưu note theo `event_id`, `event_type`, `firebase_uid`

### `attachments`

- lưu metadata file, `object_key`, MIME type và kích thước

### `personal_tasks`

- lưu task cá nhân của user

### `sync_snapshots`

- lưu bản ghi snapshot và thời điểm sync

## KV model

### Key format

```text
snapshot:{firebaseUid}:{snapshotKey}
```

### Value

- JSON string của `LocalCachePayload`

### TTL

- mặc định 6 giờ

## R2 model

### Object key format

```text
{firebaseUid}/{eventId}/{uuid}-{fileName}
```

## Mối quan hệ logic

```text
users.firebase_uid
├── notes.firebase_uid
├── attachments.firebase_uid
├── personal_tasks.firebase_uid
└── sync_snapshots.firebase_uid
```

## Nhận xét

- Schema hiện tối ưu cho CRUD cơ bản và ownership theo Firebase UID.
- Chưa có foreign key tường minh, phù hợp với quy mô nhỏ.

---

_Generated using BMAD Method `document-project` workflow_
