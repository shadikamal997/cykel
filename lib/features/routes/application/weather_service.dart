/// CYKEL — Weather Service
/// Fetches weather data and provides weather-adaptive routing recommendations

import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/advanced_route.dart';

class WeatherService {
  WeatherService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  /// Base URL for OpenWeatherMap API
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current weather for a location
  Future<WeatherForecast?> getCurrentWeather(LatLng location) async {
    try {
      final uri = Uri.parse('$_baseUrl/weather').replace(queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
      });

      final response = await _httpClient.get(uri);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parseWeatherData(data);
    } catch (e) {
      return null;
    }
  }

  /// Get weather forecast for a location (next few hours)
  /// 
  /// Returns weather forecast for the specified time or current if null
  Future<WeatherForecast?> getWeatherForecast({
    required LatLng location,
    DateTime? forecastTime,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/forecast').replace(queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
        'cnt': '8', // Next 24 hours (3-hour intervals)
      });

      final response = await _httpClient.get(uri);

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final forecastList = data['list'] as List<dynamic>;

      if (forecastList.isEmpty) return null;

      // Find the closest forecast to the requested time
      if (forecastTime != null) {
        WeatherForecast? closestForecast;
        Duration? smallestDifference;

        for (final forecast in forecastList) {
          final parsed = _parseWeatherData(forecast as Map<String, dynamic>);
          if (parsed == null) continue;

          final difference = parsed.timestamp.difference(forecastTime).abs();
          
          if (smallestDifference == null || difference < smallestDifference) {
            smallestDifference = difference;
            closestForecast = parsed;
          }
        }

        return closestForecast;
      }

      // Return first (soonest) forecast
      return _parseWeatherData(forecastList.first as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get weather along a route
  /// 
  /// Samples weather at multiple points along the route to detect
  /// varying conditions
  Future<List<WeatherForecast>> getWeatherAlongRoute({
    required List<LatLng> routePoints,
    int maxSamples = 5,
    DateTime? departureTime,
  }) async {
    if (routePoints.isEmpty) return [];

    // Sample points along the route
    final sampledPoints = _samplePoints(routePoints, maxSamples);
    final forecasts = <WeatherForecast>[];

    // Estimate time at each point (assume 18 km/h average)
    DateTime currentTime = departureTime ?? DateTime.now();

    for (int i = 0; i < sampledPoints.length; i++) {
      if (i > 0) {
        final distance = _calculateDistance(
          sampledPoints[i - 1],
          sampledPoints[i],
        );
        
        // Add time based on distance (18 km/h = 0.3 km/min)
        final minutesToAdd = (distance / 0.3).round();
        currentTime = currentTime.add(Duration(minutes: minutesToAdd));
      }

      final forecast = await getWeatherForecast(
        location: sampledPoints[i],
        forecastTime: currentTime,
      );

      if (forecast != null) {
        forecasts.add(forecast);
      }
    }

    return forecasts;
  }

  /// Calculate route weather score (0-100, higher is better)
  /// 
  /// Considers all weather forecasts along the route
  int calculateRouteWeatherScore(List<WeatherForecast> forecasts) {
    if (forecasts.isEmpty) return 50; // Neutral score

    final scores = forecasts.map((f) => f.cyclingComfortScore);
    final averageScore = scores.reduce((a, b) => a + b) ~/ scores.length;

    // Penalize if any segment has very poor weather
    final hasVeryPoorWeather = forecasts.any((f) => f.cyclingComfortScore < 30);
    if (hasVeryPoorWeather) {
      return (averageScore * 0.7).round(); // 30% penalty
    }

    return averageScore;
  }

  /// Get weather recommendations for a route
  /// 
  /// Returns human-readable recommendations based on weather conditions
  List<String> getWeatherRecommendations(List<WeatherForecast> forecasts) {
    if (forecasts.isEmpty) return [];

    final recommendations = <String>[];
    
    // Check for rain
    final hasRain = forecasts.any((f) => 
        f.condition == WeatherCondition.rain || 
        f.condition == WeatherCondition.heavyRain);
    
    if (hasRain) {
      recommendations.add('🌧️ Rain expected - bring rain gear');
    }

    // Check for high precipitation chance
    final maxPrecipChance = forecasts.map((f) => f.precipitationChance).reduce(
      (a, b) => a > b ? a : b,
    );
    
    if (maxPrecipChance > 60 && !hasRain) {
      recommendations.add('☔ High chance of rain ($maxPrecipChance%) - consider postponing');
    }

    // Check for strong winds
    final maxWindSpeed = forecasts.map((f) => f.windSpeedKmh).reduce(
      (a, b) => a > b ? a : b,
    );
    
    if (maxWindSpeed > 30) {
      recommendations.add('💨 Strong winds expected (${maxWindSpeed.round()} km/h)');
    } else if (maxWindSpeed > 20) {
      recommendations.add('🍃 Moderate winds (${maxWindSpeed.round()} km/h) - may slow you down');
    }

    // Check for temperature extremes
    final avgTemp = forecasts.map((f) => f.temperatureC).reduce((a, b) => a + b) / 
        forecasts.length;
    
    if (avgTemp < 5) {
      recommendations.add('🥶 Cold weather (${avgTemp.round()}°C) - dress warmly');
    } else if (avgTemp > 30) {
      recommendations.add('🥵 Hot weather (${avgTemp.round()}°C) - stay hydrated');
    }

    // Check for UV index
    final maxUV = forecasts
        .where((f) => f.uvIndex != null)
        .map((f) => f.uvIndex!)
        .fold(0, (a, b) => a > b ? a : b);
    
    if (maxUV >= 7) {
      recommendations.add('☀️ High UV index ($maxUV) - use sunscreen');
    }

    // Overall assessment
    final avgScore = calculateRouteWeatherScore(forecasts);
    
    if (avgScore >= 80) {
      recommendations.insert(0, '✅ Excellent weather for cycling!');
    } else if (avgScore >= 60) {
      recommendations.insert(0, '👍 Good weather for cycling');
    } else if (avgScore >= 40) {
      recommendations.insert(0, '⚠️ Fair weather - be prepared for conditions');
    } else {
      recommendations.insert(0, '❌ Poor weather conditions - consider rescheduling');
    }

    return recommendations;
  }

  /// Find the best time to start a route based on weather
  /// 
  /// Checks weather forecasts over the next 24 hours and returns
  /// the optimal departure time
  Future<DateTime?> findBestDepartureTime({
    required List<LatLng> routePoints,
    required int estimatedDurationMinutes,
  }) async {
    if (routePoints.isEmpty) return null;

    final now = DateTime.now();
    DateTime? bestTime;
    int bestScore = 0;

    // Check weather for different start times (every 3 hours)
    for (int hourOffset = 0; hourOffset < 24; hourOffset += 3) {
      final testTime = now.add(Duration(hours: hourOffset));
      
      final forecasts = await getWeatherAlongRoute(
        routePoints: routePoints,
        departureTime: testTime,
      );

      final score = calculateRouteWeatherScore(forecasts);
      
      if (score > bestScore) {
        bestScore = score;
        bestTime = testTime;
      }
    }

    return bestTime;
  }

  /// Parse weather data from API response
  WeatherForecast? _parseWeatherData(Map<String, dynamic> data) {
    try {
      final weatherList = data['weather'] as List<dynamic>;
      if (weatherList.isEmpty) return null;

      final weather = weatherList.first as Map<String, dynamic>;
      final main = data['main'] as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>;

      // Map OpenWeatherMap conditions to our WeatherCondition enum
      final condition = _mapWeatherCondition(
        weather['main'] as String,
        wind['speed'] as num,
      );

      // Get wind direction (degrees to cardinal)
      String? windDirection;
      if (wind['deg'] != null) {
        windDirection = _degreesToCardinal((wind['deg'] as num).toInt());
      }

      return WeatherForecast(
        condition: condition,
        temperatureC: (main['temp'] as num).toDouble(),
        windSpeedKmh: (wind['speed'] as num).toDouble() * 3.6, // m/s to km/h
        precipitationChance: data['pop'] != null 
            ? ((data['pop'] as num) * 100).toInt() 
            : 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (data['dt'] as num).toInt() * 1000,
        ),
        windDirection: windDirection,
        humidity: (main['humidity'] as num?)?.toInt(),
        uvIndex: data['uvi'] != null ? (data['uvi'] as num).toInt() : null,
      );
    } catch (e) {
      return null;
    }
  }

  /// Map OpenWeatherMap condition to our WeatherCondition enum
  WeatherCondition _mapWeatherCondition(String condition, num windSpeed) {
    final conditionLower = condition.toLowerCase();

    // Check for windy conditions first
    if (windSpeed > 30 / 3.6) {
      return WeatherCondition.windy;
    }

    if (conditionLower.contains('clear')) {
      return WeatherCondition.clear;
    } else if (conditionLower.contains('cloud')) {
      if (conditionLower.contains('few') || conditionLower.contains('scattered')) {
        return WeatherCondition.partlyCloudy;
      }
      return WeatherCondition.cloudy;
    } else if (conditionLower.contains('rain')) {
      if (conditionLower.contains('heavy') || conditionLower.contains('extreme')) {
        return WeatherCondition.heavyRain;
      }
      return WeatherCondition.rain;
    } else if (conditionLower.contains('snow')) {
      return WeatherCondition.snow;
    } else if (conditionLower.contains('fog') || 
               conditionLower.contains('mist') ||
               conditionLower.contains('haze')) {
      return WeatherCondition.fog;
    }

    return WeatherCondition.clear;
  }

  /// Convert degrees to cardinal direction
  String _degreesToCardinal(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Sample points evenly from a path
  List<LatLng> _samplePoints(List<LatLng> points, int maxSamples) {
    if (points.length <= maxSamples) return points;

    final sampledPoints = <LatLng>[];
    final step = points.length / maxSamples;

    for (int i = 0; i < maxSamples; i++) {
      final index = (i * step).floor();
      sampledPoints.add(points[index]);
    }

    if (sampledPoints.last != points.last) {
      sampledPoints.add(points.last);
    }

    return sampledPoints;
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = point1.latitude * (3.14159265359 / 180);
    final lat2Rad = point2.latitude * (3.14159265359 / 180);
    final deltaLat = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final deltaLng = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.pow(math.sin(deltaLng / 2), 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadiusKm * c;
  }

  void dispose() {
    _httpClient.close();
  }
}
