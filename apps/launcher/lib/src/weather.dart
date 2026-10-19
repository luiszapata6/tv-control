import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Current conditions from Open-Meteo (free, no API key).
class Weather {
  const Weather({required this.temperatureC, required this.code, required this.isDay});
  final double temperatureC;

  /// WMO weather interpretation code.
  final int code;
  final bool isDay;

  String get label => describeWmo(code);
  IconData get icon => iconForWmo(code, isDay: isDay);
  String get temperatureLabel => '${temperatureC.round()}°';

  /// Parses an Open-Meteo `current=temperature_2m,weather_code,is_day` answer.
  static Weather? fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map) return null;
    final t = current['temperature_2m'];
    final c = current['weather_code'];
    if (t is! num || c is! num) return null;
    return Weather(temperatureC: t.toDouble(), code: c.toInt(), isDay: (current['is_day'] as num?) != 0);
  }
}

/// Where to read the weather for. Medellín by default.
class WeatherPlace {
  const WeatherPlace(this.name, this.latitude, this.longitude);
  final String name;
  final double latitude;
  final double longitude;

  static const medellin = WeatherPlace('Medellín', 6.2442, -75.5812);
}

typedef HttpGet = Future<String> Function(Uri uri);

class WeatherService {
  WeatherService({HttpGet? get}) : _get = get ?? _defaultGet;
  final HttpGet _get;

  static Uri uriFor(WeatherPlace place) => Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': place.latitude.toStringAsFixed(4),
        'longitude': place.longitude.toStringAsFixed(4),
        'current': 'temperature_2m,weather_code,is_day',
        'timezone': 'auto',
      });

  /// Returns null on any failure: the weather chip simply hides.
  Future<Weather?> current(WeatherPlace place) async {
    try {
      final body = await _get(uriFor(place)).timeout(const Duration(seconds: 8));
      return Weather.fromOpenMeteo((jsonDecode(body) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  static Future<String> _defaultGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: uri);
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}

String describeWmo(int code) => switch (code) {
      0 => 'Despejado',
      1 => 'Mayormente despejado',
      2 => 'Parcialmente nublado',
      3 => 'Nublado',
      45 || 48 => 'Niebla',
      51 || 53 || 55 || 56 || 57 => 'Llovizna',
      61 || 63 || 65 || 66 || 67 => 'Lluvia',
      71 || 73 || 75 || 77 => 'Nieve',
      80 || 81 || 82 => 'Chubascos',
      85 || 86 => 'Chubascos de nieve',
      95 || 96 || 99 => 'Tormenta',
      _ => 'Clima',
    };

IconData iconForWmo(int code, {bool isDay = true}) => switch (code) {
      0 || 1 => isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
      2 => isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined,
      3 || 45 || 48 => Icons.cloud_outlined,
      51 || 53 || 55 || 56 || 57 || 61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => Icons.water_drop_outlined,
      71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit,
      95 || 96 || 99 => Icons.thunderstorm_outlined,
      _ => Icons.wb_cloudy_outlined,
    };
