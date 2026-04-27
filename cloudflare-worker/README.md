# Cloudflare Worker

## Muc dich

- Luu note, task, va tep dinh kem.
- Cache du lieu dong bo de giam so lan goi worker.

## Tai nguyen can tao

- 1 D1 database
- 1 KV namespace
- 1 R2 bucket

## Cac buoc thu cong tiep theo

1. Dang nhap Cloudflare:
```powershell
wrangler login
```

2. Cai dependency:
```powershell
cd cloudflare-worker
npm install
```

3. Tao D1:
```powershell
wrangler d1 create sinhvien-db
```

4. Tao KV:
```powershell
wrangler kv namespace create CACHE
```

5. Tao R2:
```powershell
wrangler r2 bucket create note-app
```

6. Dan cac id nhan duoc vao [wrangler.toml](./wrangler.toml)

7. Tao bang:
```powershell
wrangler d1 execute sinhvien-db --local --file=.\schema.sql
```

8. Chay local:
```powershell
wrangler dev
```

## API tam co san

- `GET /health`
- `GET /notes`
- `POST /notes`
- `GET /sync-cache?key=...`
- `POST /sync-cache`
- `POST /attachments/upload`
- `GET /attachments/download?key=...`
- `DELETE /account-data`

## Luu y

- Worker verify Firebase ID token tu header `Authorization: Bearer <Firebase ID token>` trong `src/index.ts`.
- Keep `FIREBASE_PROJECT_ID` in `wrangler.toml` matched to the real Firebase project.
- Bucket R2 va cac route upload/download phai khop voi `src/index.ts`.
