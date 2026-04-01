# Sinh Vien App

Ứng dụng Flutter hỗ trợ sinh viên theo dõi việc học, xem điểm, lịch học, lịch thi và quản lý ghi chú cá nhân trên cùng một nơi.

Project này được xây dựng theo hướng:
- đồng bộ dữ liệu thật từ cổng sinh viên của trường
- lưu local để dùng offline
- hỗ trợ đăng nhập Firebase để đồng bộ ghi chú và tệp đính kèm lên Cloudflare

## Giới thiệu

Ứng dụng phục vụ các nhu cầu chính của sinh viên:
- xem lịch học và lịch thi theo ngày
- xem bảng điểm và chương trình đào tạo
- tạo việc cá nhân, ghi chú, đính kèm tài liệu
- dùng lại dữ liệu đã lưu ngay cả khi không có mạng

Luồng sử dụng được tách thành 2 phần:
- `Đồng bộ`: dùng tài khoản sinh viên để lấy dữ liệu thật từ API của trường
- `Tài khoản`: dùng Firebase để lưu ghi chú, task, file đính kèm và snapshot lên cloud

Đăng nhập Firebase là tùy chọn. Người dùng không đăng nhập vẫn có thể đồng bộ dữ liệu trường và dùng app offline bình thường.

## Chức năng chính

### 1. Lịch học tập
- Hiển thị lịch học, lịch thi và việc cá nhân trên cùng màn hình lịch
- Có dải ngày ngang để chuyển nhanh giữa các ngày
- Có chọn ngày bằng icon lịch
- Có card tổng quan và card thời tiết ở đầu trang, vuốt ngang để chuyển qua lại
- Có thêm việc cá nhân trực tiếp từ màn hình lịch

### 2. Ghi chú và tệp đính kèm
- Ghi chú trực tiếp trên lịch học, lịch thi và việc cá nhân
- Chỉ việc cá nhân mới được xóa
- Đính kèm tệp thường, PDF, ảnh
- Chụp ảnh nhanh bằng camera để đính kèm
- Quét tài liệu từ camera và lưu dạng ảnh hoặc PDF
- Chỉnh sửa ảnh đính kèm:
  - crop
  - vẽ
  - thêm chữ
  - undo
  - xóa riêng từng nét vẽ hoặc đoạn chữ

### 3. Bảng điểm và mục tiêu học tập
- Xem bảng điểm theo dữ liệu thật từ cổng trường
- Xem chương trình đào tạo theo nhóm học phần
- Môn đã có điểm sẽ hiện điểm chữ ngay trong chương trình đào tạo
- Có phần `Mục tiêu` để nhập GPA mong muốn và nhận gợi ý học tập
- Có hỗ trợ chọn các môn bạn chắc chắn có thể đạt A

### 4. Đồng bộ dữ liệu trường
- Lấy dữ liệu từ API trường:
  - thông tin sinh viên
  - bảng điểm
  - lịch học
  - lịch thi
  - chương trình đào tạo
- Dữ liệu đồng bộ được lưu local để mở app lại vẫn còn

### 5. Firebase và Cloudflare
- Đăng nhập Google hoặc email/password bằng Firebase
- Ghi chú, task, file đính kèm và snapshot được đồng bộ lên Cloudflare
- File đính kèm được lưu trên Cloudflare R2
- Snapshot và dữ liệu hỗ trợ được lưu qua Worker + D1 + KV

### 6. Offline, thông báo và widget
- Cache local để xem dữ liệu khi offline
- Mở lại app vẫn còn dữ liệu đã đồng bộ trước đó
- Có thông báo cục bộ cho lịch học, lịch thi và việc cá nhân
- Có widget Android để xem nhanh lịch hôm nay

## Công nghệ sử dụng

- Flutter
- Firebase Core
- Firebase Auth
- Google Sign-In
- Cloudflare Worker
- Cloudflare D1
- Cloudflare KV
- Cloudflare R2

## Cấu trúc chính

- [main.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/main.dart)
- [app.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/app.dart)
- [home_shell.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/screens/home_shell.dart)
- [grades_page.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/screens/grades_page.dart)
- [school_api_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/school_api_service.dart)
- [local_cache_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/local_cache_service.dart)
- [cloud_sync_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/cloud_sync_service.dart)
- [auth_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/auth_service.dart)
- [notification_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/notification_service.dart)
- [attachment_storage_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/attachment_storage_service.dart)
- [widget_sync_service.dart](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/lib/services/widget_sync_service.dart)
- [cloudflare-worker](/E:/Thi%20gk/PTTKHTTT/sinhvien-app/cloudflare-worker)

## Cách chạy

### Yêu cầu
- Flutter SDK
- Android Studio hoặc VS Code
- Thiết bị Android thật, emulator, hoặc Chrome

### Chạy project

```powershell
git clone <repo-private>
cd sinhvien-app
flutter pub get
flutter run
```

Nếu muốn chạy trên Chrome:

```powershell
flutter run -d chrome
```

Nếu muốn chạy trên Android:

```powershell
flutter run -d android
```

## Cách dùng cơ bản

### Đồng bộ dữ liệu trường
1. Mở tab `Đồng bộ`
2. Nhấn `Đồng bộ ngay`
3. Nhập tài khoản sinh viên
4. Chờ app tải dữ liệu từ cổng trường

### Đăng nhập tài khoản ứng dụng
1. Mở tab `Tài khoản`
2. Chọn đăng nhập Google hoặc email/password
3. Sau khi đăng nhập, app sẽ đồng bộ ghi chú và dữ liệu lên cloud

### Thêm ghi chú và tệp
1. Vào tab `Lịch`
2. Chọn một sự kiện hoặc thêm việc cá nhân mới
3. Ghi chú nội dung
4. Đính kèm tệp, chụp ảnh hoặc quét tài liệu nếu cần

## Hạ tầng đang dùng chung

Project hiện đang dùng chung hạ tầng đã cấu hình sẵn:
- Firebase project của team
- Cloudflare Worker đã deploy
- Cloudflare R2 bucket để lưu file

Vì vậy với repo private nội bộ, thành viên trong team chỉ cần clone về và chạy là dùng được đầy đủ tính năng.

## Kiểm tra nhanh

```powershell
flutter analyze
flutter test
```

## Ghi chú

- Đồng bộ dữ liệu trường và đăng nhập tài khoản ứng dụng là 2 luồng khác nhau
- Dữ liệu đồng bộ từ trường vẫn dùng được ngay cả khi chưa đăng nhập Firebase
- Nếu đổi Firebase project hoặc Cloudflare Worker URL thì cần cập nhật lại repo cho cả team
