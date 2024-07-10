import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/checkin.dart';

class CheckinService {
  Future<bool> requestCheckin(String token, int locationId) async {
    try {
      if (kDebugMode) {
        print('Sending check-in request: Location ID: $locationId');
      }
      final response = await http.post(
        Uri.parse('${Constants.apiUrl}/checkin-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'locationId': locationId}),
      );

      if (kDebugMode) {
        print('Check-in request response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Check-in request response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 403) {
        return false;
      } else {
        throw Exception('Unexpected response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in requestCheckin: $e');
      }
      rethrow;
    }
  }

  Future<void> checkin(String token, int locationId, double latitude, double longitude) async {
    try {
      if (kDebugMode) {
        print('Sending check-in request: Location ID: $locationId, Lat: $latitude, Long: $longitude');
      }
      final response = await http.post(
        Uri.parse('${Constants.apiUrl}/checkin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'locationId': locationId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (kDebugMode) {
        print('Check-in response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Check-in response body: ${response.body}');
      }

      if (response.statusCode == 403) {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['error'] ?? 'Check-in failed');
      } else if (response.statusCode != 200) {
        throw Exception('Check-in failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkin: $e');
      }
      rethrow;
    }
  }

  Future<List<Checkin>> getCheckinHistory(String token) async {
    final response = await http.get(
      Uri.parse('${Constants.apiUrl}/checkin-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Checkin.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load check-in history');
    }
  }
}