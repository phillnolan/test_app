# Inventory component - mobile-app

**Part ID:** `mobile-app`  
**Phạm vi quét:** `lib/views/**`, `android/app/src/main/**`

## Tổng quan

App Flutter tổ chức component theo màn hình và widget hỗ trợ, chưa có design system tách riêng nhưng đã có nhiều reusable UI trong `home_common_widgets.dart`, dialog/sheet models và các card dùng lại theo tab.

## Nhóm điều hướng và shell

### `HomeShell`

- **File:** `lib/views/home/home_shell.dart`
- **Vai trò:** shell điều hướng 4 tab, giữ một `HomeController`, tạo `NavigationBar` và FAB thêm việc

## Nhóm lịch và event

### `SchedulePage`

- **File:** `lib/views/home/pages/schedule_page.dart`
- **Vai trò:** màn hình lịch chính theo ngày

### `_ScheduleHeroCard`

- tóm tắt nhanh số lịch học, lịch thi, việc cá nhân và event sắp tới

### `_WeatherCard`

- hiển thị forecast 7 ngày đã lọc cho ngày được chọn

### `_DayChip`

- item chọn ngày dạng pill với indicator màu theo event

### `_EventCard`

- card chính cho từng sự kiện
- hỗ trợ note, attachment, toggle done và delete cho personal task

## Nhóm đồng bộ và tài khoản

### `SyncPage`

- **File:** `lib/views/home/pages/sync_page.dart`
- **Vai trò:** trigger đồng bộ dữ liệu trường, xem profile và thống kê dữ liệu

### `AccountPage`

- **File:** `lib/views/home/pages/account_page.dart`
- **Vai trò:** login Google/email-password, sign out, giải thích offline/cloud mode

## Nhóm bảng điểm và planner

### `GradesPage`

- **File:** `lib/views/grades/grades_page.dart`
- **Vai trò:** tổng quan GPA, danh sách điểm, nhúng planner và dialog chương trình đào tạo

### `GoalPlannerSection`

- **File:** `lib/views/grades/widgets/goal_planner_section.dart`
- **Vai trò:** tính lộ trình GPA mục tiêu, chọn môn chắc A, gợi ý học lại
- **Độ phức tạp:** cao nhất trong tab điểm

### `CurriculumDialogButton` + `CurriculumSubjectsDialog`

- **File:** `lib/views/grades/widgets/curriculum_subjects_section.dart`
- **Vai trò:** xem chương trình đào tạo, nhóm theo khối kiến thức, hiển thị tiến độ hoàn thành

## Nhóm editor, sheet, dialog

### `ImageAttachmentEditor`

- **File:** `lib/views/home/image_attachment_editor.dart`
- **Vai trò:** chỉnh sửa ảnh đính kèm
- **Chức năng:** crop, vẽ, thêm chữ, undo, export lại

### `home_dialogs.dart`

- month picker, sync credentials, email auth sheet

### `home_editors.dart`

- note editor và task editor

### `home_sheet_models.dart`

- model trả về từ dialog/sheet

## Nhóm reusable/shared UI

### `home_common_widgets.dart`

- empty state
- placeholder info
- desktop-friendly scroll behavior

### `app_theme.dart`

- theme dùng chung toàn app

## Nhóm component native/platform

### Android home widget

- **Files:** `MainActivity.kt`, `TodayScheduleWidgetProvider.kt`, `today_schedule_widget.xml`
- **Vai trò:** widget lịch hôm nay ngoài màn hình chính Android
- **Tích hợp:** nhận dữ liệu từ `WidgetSyncService` qua `MethodChannel`

## Mức độ tái sử dụng

### Reusable cao

- empty/placeholder cards
- sync/account metric cards
- event card primitives
- curriculum subject cards

### Screen-specific

- `GoalPlannerSection`
- `ImageAttachmentEditor`
- `SchedulePage`
- `GradesPage`

## Design notes

- UI đang dùng Material 3 và nhiều card bo tròn lớn.
- Tab lịch là phần giàu component nhất và cũng là nơi gắn nhiều callback nhất.
- Chưa có thư mục `components/` hay design tokens riêng ngoài theme; nếu app tiếp tục lớn, có thể tách `views/shared/` hoặc `components/`.

---

_Generated using BMAD Method `document-project` workflow_
