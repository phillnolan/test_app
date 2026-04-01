# Cloudflare Worker

## Mục đích

- Lưu note, task, file đính kèm
- Cache dữ liệu đồng bộ để giảm số lần gọi cổng trường

## Tài nguyên cần tạo

- 1 D1 database
- 1 KV namespace
- 1 R2 bucket

## Các bước thủ công tiếp theo

1. Đăng nhập Cloudflare:
```powershell
wrangler login
```

2. Cài dependency:
```powershell
cd cloudflare-worker
npm install
```

3. Tạo D1:
```powershell
wrangler d1 create sinhvien-db
```

4. Tạo KV:
```powershell
wrangler kv namespace create CACHE
```

5. Tạo R2:
```powershell
wrangler r2 bucket create sinhvien-files
```

6. Dán các id nhận được vào [wrangler.toml](E:\Thi gk\sinhvien-app\cloudflare-worker\wrangler.toml)

7. Tạo bảng:
```powershell
wrangler d1 execute sinhvien-db --local --file=.\schema.sql
```

8. Chạy local:
```powershell
wrangler dev
```

## API tạm có sẵn

- `GET /health`
- `GET /notes`
- `POST /notes`
- `GET /sync-cache?key=...`
- `POST /sync-cache`
- `POST /attachments/request-upload`

## Lưu ý

- Hiện auth trong Worker đang dùng header `x-user-id` để scaffold nhanh.
- Bước tiếp theo là thay `x-user-id` bằng xác minh Firebase ID token thật.
