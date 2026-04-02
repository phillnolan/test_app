# Development Guide - worker-api

**Part ID:** `worker-api`

## Mục tiêu

Hướng dẫn chạy local và deploy Cloudflare Worker trong `cloudflare-worker/`.

## Điều kiện cần

- Node.js
- npm
- Cloudflare Wrangler CLI
- Tài khoản Cloudflare nếu muốn chạy binding thật

## Setup

```bash
cd cloudflare-worker
npm install
```

## Cấu hình hạ tầng

Worker cần:

- 1 D1 database
- 1 KV namespace
- 1 R2 bucket

Bindings hiện có trong `wrangler.toml`:

- `DB`
- `CACHE`
- `FILES`
- `APP_ENV`
- `FIREBASE_PROJECT_ID`

## Tạo schema

```bash
wrangler d1 execute sinhvien-db --local --file=./schema.sql
```

## Chạy local

```bash
npm run dev
```

## Deploy

```bash
npm run deploy
```

## Kiểm tra nhanh

```bash
curl https://<worker-host>/health
```

Route auth cần Firebase ID token hợp lệ:

```bash
curl -H "Authorization: Bearer <firebase-id-token>" https://<worker-host>/notes
```

## Gợi ý debug

- Nếu auth fail, kiểm tra `FIREBASE_PROJECT_ID`.
- Nếu upload/download attachment lỗi, kiểm tra binding R2 `FILES`.
- Nếu snapshot không đọc lại được, kiểm tra KV binding `CACHE` và TTL.
- Nếu D1 query lỗi, chạy lại schema hoặc kiểm tra tên database/binding.

## Lưu ý tài liệu cũ

`cloudflare-worker/README.md` phản ánh một thiết kế cũ hơn:

- còn nhắc `x-user-id`,
- còn nhắc `attachments/request-upload`,
- chưa mô tả đầy đủ verify Firebase token hiện tại.

---

_Generated using BMAD Method `document-project` workflow_
