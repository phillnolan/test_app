# Kiến trúc - worker-api

**Part ID:** `worker-api`  
**Loại:** `backend`  
**Root:** `cloudflare-worker/`  
**Entry point:** `cloudflare-worker/src/index.ts`

## Mục đích

`worker-api` là API serverless phục vụ phần dữ liệu cá nhân của người dùng:

- lưu note gắn với sự kiện,
- lưu personal task,
- lưu/tải file đính kèm,
- lưu snapshot dashboard đã đồng bộ,
- xác thực request bằng Firebase ID token.

Worker này không đóng vai trò backend cho dữ liệu trường. Dữ liệu trường hiện vẫn được app Flutter gọi trực tiếp từ API của trường.

## Kiến trúc tổng thể

Worker là một ứng dụng TypeScript nhỏ với:

- router thủ công dựa trên `pathname` + `method`,
- verify Firebase token bằng `jose` và Google JWKS,
- persistence đa lớp:
  - **D1** cho dữ liệu quan hệ,
  - **KV** cho snapshot nhanh,
  - **R2** cho binary attachment.

Toàn bộ logic hiện nằm trong `src/index.ts`.

## Request lifecycle

1. `fetch(request, env)` nhận request.
2. Nếu `OPTIONS`, trả CORS preflight.
3. Nếu `/health`, trả thông tin health không cần auth.
4. Các route còn lại bắt buộc qua `verifyFirebaseToken()`.
5. Sau khi auth thành công:
   - upsert user profile vào D1,
   - dispatch tới từng handler.

## Auth và bảo mật

### Xác thực

- Lấy header `Authorization: Bearer <token>`
- Dùng `jwtVerify()` với Google Secure Token JWKS
- Kiểm tra:
  - `issuer = https://securetoken.google.com/{FIREBASE_PROJECT_ID}`
  - `audience = {FIREBASE_PROJECT_ID}`
- `payload.sub` được dùng làm `firebase_uid`

### Cách ly dữ liệu

Mọi dữ liệu user-level đều bị ràng buộc bởi `firebase_uid`:

- query notes theo `firebase_uid`
- lookup attachment theo `firebase_uid` + `object_key`
- KV key có prefix user

### CORS

Worker đang bật:

- `access-control-allow-origin: *`
- methods: `GET,POST,OPTIONS`
- headers: `content-type,authorization,x-file-name,x-event-id`

## Các lớp dữ liệu

### D1

- `users`: danh tính Firebase cơ bản
- `notes`: ghi chú theo event
- `attachments`: metadata file
- `personal_tasks`: task cá nhân
- `sync_snapshots`: log snapshot đã lưu

### KV

- key pattern: `snapshot:{firebaseUid}:{snapshotKey}`
- dùng cho cache dashboard
- TTL mặc định 6 giờ

### R2

- object key pattern: `{firebaseUid}/{eventId}/{uuid}-{fileName}`
- lưu binary attachment thực tế

## Các route chính

- `GET /health`
- `GET /notes`
- `POST /notes`
- `POST /tasks`
- `POST /sync-cache`
- `GET /sync-cache?key=...`
- `POST /attachments/upload`
- `GET /attachments/download?key=...`

Chi tiết request/response xem tại [api-contracts-worker-api.md](./api-contracts-worker-api.md).

## Bindings và cấu hình

Từ `wrangler.toml`:

- **D1 binding:** `DB`
- **KV binding:** `CACHE`
- **R2 binding:** `FILES`
- **Vars:** `APP_ENV`, `FIREBASE_PROJECT_ID`

`compatibility_date` hiện là `2026-04-01`.

## Điểm mạnh hiện tại

- Đơn giản, dễ deploy, ít moving parts.
- Xác thực Firebase token đã được triển khai thật, không còn trạng thái scaffold cũ.
- Có phân tầng lưu trữ hợp lý: D1 cho metadata, KV cho snapshot nhanh, R2 cho file.
- Phù hợp với use case sync dữ liệu cá nhân và file đính kèm.

## Điểm hạn chế hiện tại

- Toàn bộ route và persistence logic nằm trong một file duy nhất.
- Chưa có test tự động cho Worker.
- Chưa có update/delete routes cho note/task.
- CORS đang mở hoàn toàn, chưa whitelist origin.
- Error handling còn tối giản; client không luôn nhận được chi tiết lỗi giàu ngữ cảnh.

## Hướng mở rộng hợp lý

- Tách `src/index.ts` thành `auth`, `routes`, `storage`, `responses`.
- Thêm schema validation cho request body.
- Bổ sung route `DELETE`/`PATCH` cho note, task, attachment.
- Nếu snapshot lớn hơn, cân nhắc chiến lược versioning hoặc nén payload.
- Thêm rate limiting hoặc origin restriction trước khi public rộng hơn.

---

_Generated using BMAD Method `document-project` workflow_
