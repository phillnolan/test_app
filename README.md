# Sinh Vien App

Ung dung Flutter ho tro sinh vien:

- dong bo diem, lich hoc, lich thi tu cong truong
- them ghi chu va task ca nhan
- dinh kem file pdf, doc, docx, hinh anh
- luu local de dung offline
- dong bo cloud qua Firebase + Cloudflare

Repo nay duoc thiet ke cho team private dung chung ha tang da cau hinh san.

## Clone la chay

Neu repo private nay da bao gom day du file cau hinh Firebase, thanh vien trong team chi can:

```powershell
git clone <repo-private>
cd sinhvien-app
flutter pub get
flutter run
```

App da duoc tro san Cloudflare Worker URL, nen khong can truyen them `--dart-define` de dung cloud.

## App hoat dong nhu the nao

Co 2 luong tach biet:

- `Dong bo`: dang nhap tai khoan sinh vien de lay du lieu that tu API truong
- `Tai khoan`: dang nhap Firebase de luu ghi chu, tep dinh kem va snapshot len cloud

Dang nhap Firebase khong bat buoc de xem du lieu truong. Neu khong dang nhap, app van luu local offline tren may.

## Ha tang dang dung chung

- Firebase Auth cho Google va email/password
- Cloudflare Worker:
  `https://sinhvien-worker.nkocpk99012.workers.dev`
- Cloudflare D1 de luu notes va tasks
- Cloudflare KV de luu snapshot
- Cloudflare R2 bucket `note-app` de luu file dinh kem

## Khi nao can cau hinh them

Thanh vien trong team thuong khong can cai Firebase CLI hay Wrangler chi de chay app.

Chi can cau hinh them neu:

- can doi Firebase project
- can doi Cloudflare Worker
- can tu deploy lai backend

## Neu can deploy lai Cloudflare Worker

Thu muc Worker:

- [cloudflare-worker](/E:/Thi%20gk/sinhvien-app/cloudflare-worker)

Lenh co ban:

```powershell
cd E:\Thi gk\sinhvien-app\cloudflare-worker
npm install
npx wrangler deploy
```

## Kiem tra nhanh

```powershell
flutter analyze
flutter test
```

## File quan trong

- [main.dart](/E:/Thi%20gk/sinhvien-app/lib/main.dart)
- [app.dart](/E:/Thi%20gk/sinhvien-app/lib/app.dart)
- [home_shell.dart](/E:/Thi%20gk/sinhvien-app/lib/screens/home_shell.dart)
- [school_api_service.dart](/E:/Thi%20gk/sinhvien-app/lib/services/school_api_service.dart)
- [local_cache_service.dart](/E:/Thi%20gk/sinhvien-app/lib/services/local_cache_service.dart)
- [cloud_sync_service.dart](/E:/Thi%20gk/sinhvien-app/lib/services/cloud_sync_service.dart)
- [auth_service.dart](/E:/Thi%20gk/sinhvien-app/lib/services/auth_service.dart)
- [index.ts](/E:/Thi%20gk/sinhvien-app/cloudflare-worker/src/index.ts)
- [wrangler.toml](/E:/Thi%20gk/sinhvien-app/cloudflare-worker/wrangler.toml)

## Luu y cho repo private

- Team nay dang dung chung Firebase va Cloudflare cua ban
- Thanh vien clone repo ve se co the dung day du cac tinh nang neu file cau hinh da duoc commit
- Neu ban doi Worker URL hoac Firebase project, hay cap nhat repo de ca team dung dong bo
