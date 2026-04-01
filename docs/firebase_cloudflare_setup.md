# Firebase + Cloudflare Setup

## Mục tiêu

- Firebase:
  - Đăng nhập Google
  - Đăng ký / đăng nhập email-password
  - Quản lý tài khoản người dùng
- Cloudflare:
  - Lưu file đính kèm
  - Lưu ghi chú, task và dữ liệu đồng bộ để giảm số lần gọi cổng trường

## Kiến trúc đề xuất

1. Flutter app
   - Đăng nhập bằng Firebase Auth.
   - Gọi API riêng của bạn trên Cloudflare Worker.
   - Không gọi trực tiếp Cloudflare R2 hay D1 từ app production.

2. Firebase Auth
   - Xác thực người dùng.
   - Trả về Firebase ID token.
   - App gửi token đó tới Cloudflare Worker.

3. Cloudflare Worker
   - Xác minh Firebase ID token.
   - Đọc / ghi dữ liệu ghi chú và cache đồng bộ.
   - Trả signed URL để upload file lên R2 hoặc upload qua Worker.

4. Cloudflare D1
   - Lưu structured data:
     - users
     - notes
     - attachments
     - sync_snapshots
     - personal_tasks

5. Cloudflare R2
   - Lưu PDF, DOC, DOCX, ảnh đính kèm.

6. Cloudflare KV
   - Cache JSON tổng hợp cho dashboard theo user.

## Phân chia dữ liệu

- Firebase Auth:
  - uid
  - email
  - displayName
  - photoURL
  - provider

- Cloudflare D1:
  - metadata ghi chú
  - mapping sự kiện <-> ghi chú
  - task cá nhân
  - cache đồng bộ gần nhất
  - lịch học / lịch thi đã chuẩn hóa

- Cloudflare R2:
  - file thật

- Cloudflare KV:
  - dashboard cache
  - marks cache
  - timetable cache
  - exams cache

## Luồng đăng nhập

1. Người dùng đăng nhập bằng Firebase Auth.
2. Flutter lấy Firebase ID token.
3. Flutter gọi Cloudflare Worker kèm header `Authorization: Bearer <firebase_id_token>`.
4. Worker xác minh token.
5. Worker dùng `uid` làm khóa dữ liệu chính.

## Luồng đồng bộ

1. App gọi `POST /sync`.
2. Worker kiểm tra KV cache.
3. Nếu cache còn hạn:
   - trả dữ liệu ngay.
4. Nếu cache hết hạn:
   - Worker gọi scraper / service nội bộ để đồng bộ từ cổng trường.
   - Ghi D1.
   - Cập nhật KV.
   - Trả snapshot mới.

## Luồng upload file

1. App gọi `POST /attachments/request-upload`.
2. Worker tạo object key trong R2.
3. Worker trả thông tin upload.
4. App upload file.
5. App gọi `POST /attachments/commit`.
6. Worker ghi metadata vào D1.

## Schema gợi ý cho D1

### users

- id
- firebase_uid
- email
- display_name
- created_at
- updated_at

### notes

- id
- user_id
- event_id
- event_type
- content
- created_at
- updated_at

### attachments

- id
- user_id
- note_id
- file_name
- object_key
- content_type
- size_bytes
- created_at

### personal_tasks

- id
- user_id
- title
- note
- start_at
- end_at
- is_done
- created_at
- updated_at

### sync_snapshots

- id
- user_id
- source_key
- payload_json
- synced_at
- expires_at

## TTL gợi ý

- Bảng điểm: 12 giờ
- Lịch học: 6 giờ
- Lịch thi: 12 giờ
- Dashboard tổng hợp: 2 giờ

## Việc bạn cần làm thủ công

### Firebase

1. `firebase login`
2. Tạo hoặc chọn Firebase project
3. Bật:
   - Authentication
   - Google provider
   - Email/Password provider
4. Cài FlutterFire CLI nếu chưa có
5. Chạy:
   - `dart pub global activate flutterfire_cli`
   - `flutterfire configure`

### Cloudflare

1. `wrangler login`
2. Tạo:
   - 1 Worker
   - 1 D1 database
   - 1 R2 bucket
   - 1 KV namespace
3. Khai báo bindings trong `wrangler.toml`
4. Tạo secret:
   - Firebase project id
   - Firebase service verification config nếu cần

## Bước tiếp theo nên làm

1. Tích hợp Firebase Auth vào Flutter.
2. Tạo Cloudflare Worker API cơ bản.
3. Đưa ghi chú / task / attachment lên Worker.
4. Sau đó mới chuyển phần sync dữ liệu trường sang cache qua Worker.
