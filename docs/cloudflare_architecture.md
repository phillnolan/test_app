# Sinh vien app - de xuat Cloudflare architecture

## Muc tieu

- Giam so lan app phai goi truc tiep vao web truong vi response cham.
- Luu ban sao du lieu hoc tap cua sinh vien de mo app nhanh hon.
- Dong bo task va ghi chu do sinh vien tao tren lich hoc, lich thi.

## Kien truc de xuat

1. Flutter app
   - Dang nhap vao he thong cua ban.
   - Goi `Worker API` de lay marks, timetable, exams, profile, notes.
   - Khong chua username/password cua cong truong trong source code.

2. Cloudflare Worker
   - Xac thuc nguoi dung.
   - Kiem tra cache theo `studentId + semester`.
   - Neu cache con han thi tra JSON ngay.
   - Neu cache het han thi goi backend scraper de cap nhat.

3. Python scraper service
   - Tai su dung 4 file trong `python/`.
   - Nen tach phan login va fetch thanh ham, khong hard-code tai khoan trong file.
   - Output tra ve JSON thay vi ghi file local khi deploy production.

4. Cloudflare D1
   - Luu du lieu co cau truc: students, marks, timetables, exams, notes, personal_tasks.
   - Phu hop cho query lich theo ngay va merge note vao tung item.

5. Cloudflare KV
   - Cache JSON tong hop theo key nhu `student:2251162091:dashboard:2026-2`.
   - TTL de xuat: bang diem 6-12 gio, lich hoc 3-6 gio, lich thi 12-24 gio.

## Luong du lieu

1. Sinh vien dang nhap vao app.
2. App goi `GET /dashboard`.
3. Worker doc cache KV.
4. Neu co cache hop le, tra ngay cho app.
5. Neu khong co, Worker goi scraper service.
6. Scraper login vao cong truong, lay JSON, tra lai cho Worker.
7. Worker ghi D1, cap nhat KV, sau do tra ket qua cho Flutter.
8. Khi sinh vien them task hoac note, app goi `POST /notes` hoac `POST /tasks`.
9. Worker ghi D1 va xoa cache lien quan de lan sau render du lieu moi.

## Bao mat

- Khong commit username/password that cua sinh vien vao repo.
- Nen ma hoa credentials truoc khi luu, hoac dung session token ngan han.
- Worker chi nen giu secret trong Cloudflare Secrets.
- Them rate limiting de tranh bi chan tu cong truong.

## API goi y

- `POST /auth/login`
- `GET /dashboard?semester=2026-2`
- `GET /marks?semester=2026-2`
- `GET /timetable?from=2026-04-01&to=2026-04-30`
- `GET /exams?semester=2026-2`
- `POST /notes`
- `POST /tasks`
- `PATCH /tasks/:id`

