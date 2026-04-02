# Cau truc thu muc theo MVC

Tai lieu nay mo ta cau truc hien tai cua thu muc `lib/` theo huong MVC thuc dung.

## Cay thu muc hien tai

```text
lib/
|-- app.dart
|-- firebase_options.dart
|-- main.dart
|-- controllers/
|   |-- account_auth_controller.dart
|   |-- grades_controller.dart
|   |-- home_controller.dart
|   `-- home_flow_models.dart
|-- models/
|   |-- event_attachment.dart
|   |-- grade_item.dart
|   |-- home_action_result.dart
|   |-- local_cache_payload.dart
|   |-- program_subject.dart
|   |-- school_sync_snapshot.dart
|   |-- student_event.dart
|   |-- student_profile.dart
|   |-- weather_forecast.dart
|   `-- weather_presentation.dart
|-- services/
|   |-- attachment_opener.dart
|   |-- attachment_opener_io.dart
|   |-- attachment_opener_stub.dart
|   |-- attachment_opener_web.dart
|   |-- attachment_import_service.dart
|   |-- attachment_storage_service.dart
|   |-- auth_service.dart
|   |-- cloud_sync_service.dart
|   |-- dashboard_persistence_service.dart
|   |-- device_effects_service.dart
|   |-- event_mutation_service.dart
|   |-- file_bytes_reader_io.dart
|   |-- file_bytes_reader_stub.dart
|   |-- http_client_factory.dart
|   |-- http_client_factory_io.dart
|   |-- http_client_factory_stub.dart
|   |-- http_client_factory_web.dart
|   |-- local_cache_service.dart
|   |-- notification_service.dart
|   |-- school_api_service.dart
|   |-- school_sync_coordinator.dart
|   |-- weather_service.dart
|   |-- image_edit_service.dart
|   `-- widget_sync_service.dart
|-- theme/
|   `-- app_theme.dart
|-- utils/
|   |-- curriculum_presenter.dart
|   |-- grade_metrics.dart
|   `-- home_calendar_utils.dart
`-- views/
    |-- grades/
    |   |-- grades_page.dart
    |   `-- widgets/
    |       |-- curriculum_subjects_section.dart
    |       `-- goal_planner_section.dart
    `-- home/
        |-- home_shell.dart
        |-- image_attachment_editor.dart
        |-- pages/
        |   |-- account_page.dart
        |   |-- schedule_page.dart
        |   `-- sync_page.dart
        `-- widgets/
            |-- attachment_editing_helpers.dart
            |-- home_common_widgets.dart
            |-- home_dialogs.dart
            `-- home_editors.dart
```

## Nguyen tac to chuc

- `views/`: render UI, mo dialog/sheet/snackbar, giu state cuc bo cua form.
- `controllers/`: giu state man hinh, dieu phoi flow, goi service, tra ve result typed cho view.
- `models/`: entity, DTO, payload, typed result va presentation object dung chung qua ranh gioi MVC.
- `services/`: xu ly ky thuat, persistence, network, cloud, device integration.
- `utils/`: ham thuan, presenter va calculator khong can state.
- `theme/`: cau hinh giao dien dung chung.

## Luong khoi dong app

`main.dart` -> `app.dart` -> `views/home/home_shell.dart`

## Controllers

### `account_auth_controller.dart`

- Boc `AuthService`.
- Xu ly sign in email, Google va sign out.
- Lang nghe auth state.
- Khong mo UI truc tiep; view tu quyet dinh snackbar hay sheet.

### `home_controller.dart`

- Controller trung tam cua `HomeShell`.
- Giu state cho 4 tab: lich, diem, dong bo, tai khoan.
- Dieu phoi state man hinh, weather, auth listener, selected date va callback nghiep vu cho 4 tab.
- Uy quyen school sync cho `school_sync_coordinator.dart`.
- Uy quyen local/cloud persistence cho `dashboard_persistence_service.dart`.
- Uy quyen task/note/attachment mutation cho `event_mutation_service.dart`.
- Nhan input typed tu view va tra typed result cho cac flow can phan hoi UI.
- Khong so huu `ScrollController`, `WidgetsBinding`, hay day-strip side effect; cac UI concern nay nam o `home_shell.dart`.

### `grades_controller.dart`

- Screen controller rieng cho tab diem.
- Giu metrics GPA, state planner muc tieu va curriculum filter state.
- Ghep `grade_metrics.dart` va `curriculum_presenter.dart` thanh state san sang de view render.
- Khong mo dialog hay giu `BuildContext`; view van so huu UI ephemeral.

### `home_flow_models.dart`

- Chua cac input DTO do view tra ve cho controller.
- Hien gom `CredentialsResult`, `TaskEditorResult`, `NoteEditorResult`, `EmailAuthResult`.
- Khong chua domain model dung chung toan app.

## Models

### Core entities

- `event_attachment.dart`: mo ta tep dinh kem.
- `grade_item.dart`: mo ta mot dong diem.
- `program_subject.dart`: mo ta mot mon trong chuong trinh dao tao.
- `school_sync_snapshot.dart`: goi du lieu tra ve sau mot lan sync truong.
- `student_event.dart`: mo ta su kien lich hoc, lich thi, task ca nhan.
- `student_profile.dart`: thong tin tai khoan sinh vien.
- `weather_forecast.dart`: du lieu du bao thoi tiet thuan.

### Payload / result / presentation

- `local_cache_payload.dart`: snapshot local-first cua dashboard, duoc dung chung boi controller, local cache va cloud sync.
- `home_action_result.dart`: `HomeActionResult` va `AttachmentOpenResult` cho cac flow controller -> view.
- `weather_presentation.dart`: du lieu presentation tra ve cho UI thoi tiet.

## Views

### `views/home`

- `home_shell.dart`: entry view chinh, bind `HomeController`, dung `IndexedStack`, mo dialog/sheet/snackbar, so huu `ScrollController` cua day strip, va xu ly `post-frame` jump/animate cho lich ngang.
- `image_attachment_editor.dart`: man hinh chinh sua anh attachment, giu state UI va gesture; decode, hit-test, render anh di qua `image_edit_service.dart`.
- `pages/account_page.dart`: UI tab tai khoan.
- `pages/schedule_page.dart`: UI tab lich, weather card, day strip, danh sach event.
- `pages/sync_page.dart`: UI tab dong bo va metric profile.
- `widgets/home_dialogs.dart`: dialog va sheet nhe nhu month picker, sync credentials, email auth.
- `widgets/home_editors.dart`: editor cho note/task.
- `widgets/attachment_editing_helpers.dart`: helper view-level cho picker/camera flow, mo image editor, sheet chon output va hien snackbar loi.
- `widgets/home_common_widgets.dart`: widget dung chung trong nhom home.

### `views/grades`

- `grades_page.dart`: tao va bind `GradesController` vao tab diem.
- `widgets/curriculum_subjects_section.dart`: render chuong trinh dao tao dua tren filter state cua controller.
- `widgets/goal_planner_section.dart`: render planner GPA va gui input typed len controller.
- View grades chi render va mo dialog; state co the test duoc nam o `grades_controller.dart`.

## Services

### Auth

- `auth_service.dart`

### Sync, API, cache

- `school_api_service.dart`
- `cloud_sync_service.dart`
- `local_cache_service.dart`
- `school_sync_coordinator.dart`
- `dashboard_persistence_service.dart`
- `event_mutation_service.dart`

### Attachment, file, open document

- `attachment_import_service.dart`
- `attachment_storage_service.dart`
- `attachment_opener.dart`
- `attachment_opener_io.dart`
- `attachment_opener_stub.dart`
- `attachment_opener_web.dart`
- `image_edit_service.dart`
- `file_bytes_reader_io.dart`
- `file_bytes_reader_stub.dart`

### HTTP da nen tang

- `http_client_factory.dart`
- `http_client_factory_io.dart`
- `http_client_factory_stub.dart`
- `http_client_factory_web.dart`

### Device integration

- `notification_service.dart`
- `widget_sync_service.dart`
- `device_effects_service.dart`

### Du lieu phu tro

- `weather_service.dart`

## Utils

### `curriculum_presenter.dart`

- dedupe mon hoc trong chuong trinh dao tao
- group mon theo presentation order de view render dialog
- ghep trang thai da qua mon va diem chu tu danh sach grades

### `grade_metrics.dart`

- tinh GPA va tong tin chi duoc count
- chua rule passing grade dung chung
- tinh goal planner defaults va ket qua goi y hoc lai

### `home_calendar_utils.dart`

- helper thuan cho lich
- format ngay gio
- map index sang date
- tinh indicator cho lich
- so sanh ngay

## Quan he phu thuoc chinh

### Luong Home

`views/home/*`
-> `controllers/home_controller.dart`
-> `controllers/account_auth_controller.dart` hoac `services/*`
-> `models/*`

### Luong Grades

`views/grades/*`
-> `controllers/grades_controller.dart`
-> `utils/grade_metrics.dart`, `utils/curriculum_presenter.dart`
-> `models/*`

## Huong mo rong tiep theo

- Tach them service nho tu `HomeController` khi mot use case da du lon va can test doc lap.
- Chuyen helper dung chung nhieu noi sang `utils/` hoac module phu hop hon neu can.
