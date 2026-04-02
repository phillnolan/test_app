# Deployment Guide

**Ngày quét:** 2026-04-02T14:13:05+07:00

## Phạm vi

Repo hiện không có pipeline CI/CD tự động. Việc deploy chủ yếu là thủ công cho:

- Cloudflare Worker
- tài nguyên Cloudflare đi kèm
- cấu hình Firebase cho app Flutter

## 1. Firebase cho mobile-app

- `firebase.json` và `lib/firebase_options.dart` đã có cấu hình cho Android và Web
- `android/app/google-services.json` đã tồn tại
- Khi đổi project Firebase, cần chạy lại `flutterfire configure` và giữ `FIREBASE_PROJECT_ID` ở Worker đồng bộ với project đó

## 2. Cloudflare Worker

### Tài nguyên cần có

- D1 database: `sinhvien-db`
- KV namespace: `CACHE`
- R2 bucket: `note-app`

### Áp schema D1

```bash
cd cloudflare-worker
wrangler d1 execute sinhvien-db --file=./schema.sql
```

### Deploy Worker

```bash
cd cloudflare-worker
npm install
npm run deploy
```

## 3. Đồng bộ URL Worker về app

Mặc định app dùng:

```text
https://sinhvien-worker.nkocpk99012.workers.dev
```

Nếu deploy Worker khác:

```bash
flutter run --dart-define=CLOUDFLARE_WORKER_URL=https://new-worker.example.workers.dev
```

## 4. Kiểm tra sau deploy

- `GET /health` trả `ok: true`
- login Firebase thành công
- note/task lưu lên Worker được
- snapshot khôi phục lại được
- attachment upload/download thành công

## 5. Điều chưa có

- Chưa thấy `.github/workflows/` hay cấu hình CI/CD khác
- Chưa có môi trường staging/production tách biệt rõ
- Chưa có secret management mô tả chi tiết trong repo

---

_Generated using BMAD Method `document-project` workflow_
