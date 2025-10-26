import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/location_config.dart';
import '../../../features/auth/services/auth_service.dart';

class LocationData {
  final Area area;
  final Cell cell;

  LocationData({required this.area, required this.cell});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      area: Area.fromJson(json['area']),
      cell: Cell.fromJson(json['cell']),
    );
  }
}

class Area {
  final int id;
  final String name;

  Area({required this.id, required this.name});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(id: json['id'], name: json['name']);
  }
}

class Cell {
  final int id;
  final String geoHash;
  final List<double> location;

  Cell({required this.id, required this.geoHash, required this.location});

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      id: json['id'],
      geoHash: json['geo_hash'],
      location: List<double>.from(json['location']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cell && other.geoHash == geoHash;
  }

  @override
  int get hashCode => geoHash.hashCode;
}

class LocationApiService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  final AuthService _authService = AuthService();

  Future<LocationData?> getCurrentLocation(double lat, double lon) async {
    final uri = Uri.parse('$_baseUrl/current?lat=$lat&lon=$lon');

    LocationConfig.log('LocationApiService', '🌐 API呼び出し: GET $uri');

    try {
      final response = await http.get(
        uri,
        headers: _authService.getAuthHeaders(),
      );

      LocationConfig.log(
        'LocationApiService',
        '📡 API応答: ステータス ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final locationData = LocationData.fromJson(data);

        LocationConfig.log(
          'LocationApiService',
          '✅ セル情報取得成功: ${locationData.cell.geoHash} (area: ${locationData.area.name})',
        );

        return locationData;
      }

      LocationConfig.log(
        'LocationApiService',
        '⚠️ セル情報取得失敗: ステータス ${response.statusCode}',
      );

      return null;
    } catch (e) {
      LocationConfig.log('LocationApiService', '❌ セル情報取得エラー: $e');
      return null;
    }
  }
}
