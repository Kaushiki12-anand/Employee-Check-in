import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AuthService {
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.apiUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<void> register(String name, String email, String mobile, String grade, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.apiUrl}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'mobile': mobile,
        'grade': grade,
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register');
    }
  }
}