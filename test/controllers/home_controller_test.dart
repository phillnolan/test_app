import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinhvien_app/controllers/account_auth_controller.dart';
import 'package:sinhvien_app/controllers/home_controller.dart';
import 'package:sinhvien_app/models/weather_forecast.dart';
import 'package:sinhvien_app/services/auth_service.dart';
import 'package:sinhvien_app/services/local_cache_service.dart';
import 'package:sinhvien_app/services/weather_service.dart';

void main() {
  testWidgets('HomeController exposes weather presentation for the selected day', (
    WidgetTester tester,
  ) async {
    final controller = HomeController(
      accountAuthController: AccountAuthController(authService: _FakeAuthService()),
      localCacheService: _FakeLocalCacheService(),
      weatherService: _FixedWeatherService(),
    );

    controller.initialize();
    await tester.pump();

    final weather = controller.selectedDayWeather;

    expect(weather, isNotNull);
    expect(weather!.description, 'Troi quang');
    expect(weather.temperatureRangeLabel, '24° - 31°');
    expect(weather.precipitationLabel, 'Mua 20%');
    expect(weather.suggestions, isNotEmpty);

    controller.dispose();
  });
}

class _FakeAuthService extends AuthService {
  @override
  bool get isAvailable => false;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();
}

class _FakeLocalCacheService extends LocalCacheService {
  @override
  Future<LocalCachePayload?> load() async => null;

  @override
  Future<void> save(LocalCachePayload payload) async {}
}

class _FixedWeatherService extends WeatherService {
  @override
  Future<WeatherForecast> fetchForecast() async {
    final now = DateTime.now();
    return WeatherForecast(
      locationLabel: 'Ha Noi',
      days: [
        WeatherDayForecast(
          date: DateTime(now.year, now.month, now.day),
          weatherCode: 0,
          temperatureMin: 24,
          temperatureMax: 31,
          precipitationProbabilityMax: 20,
          windSpeedMax: 12,
        ),
      ],
      fetchedAt: now,
    );
  }

  @override
  String descriptionForCode(int code) => 'Troi quang';

  @override
  List<String> suggestionsForDay(WeatherDayForecast forecast) {
    return const ['Thoi tiet on, co the di hoc binh thuong.'];
  }
}
