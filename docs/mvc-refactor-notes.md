## MVC Refactor Notes

- `lib/controllers/home_flow_models.dart` now holds the typed DTOs shared by the `home` and `account` flows.
- `HomeController` prepares `WeatherPresentation` for the schedule UI so `SchedulePage` no longer depends directly on `WeatherService`.
- Dialogs, sheets, and snackbar feedback stay in the view layer, while controllers only receive normalized input and return typed results.
