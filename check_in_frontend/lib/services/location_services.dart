import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/location.dart';

class LocationService {
  Future<List<Location>> getLocations(String token) async {
    try {
      if (kDebugMode) {
        print('Fetching locations from ${Constants.apiUrl}/locations');
      }
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/locations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) {
          try {
            return Location.fromJson(json);
          } catch (e) {
            print('Error parsing location: $e');
            return null;
          }
        }).where((location) => location != null).cast<Location>().toList();
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching locations: $e');
      }
      throw Exception('Failed to load locations: $e');
    }
  }
}