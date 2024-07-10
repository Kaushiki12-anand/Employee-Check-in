import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/location_services.dart';
import 'checkin_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({super.key, required this.token});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationService = LocationService();
  List<Location> _locations = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final locations = await _locationService.getLocations(widget.token);
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error),
            ElevatedButton(
              onPressed: _loadLocations,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _locations.isEmpty
          ? const Center(child: Text('No locations available'))
          : ListView.builder(
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return ListTile(
            title: Text(location.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckinScreen(
                    token: widget.token,
                    location: location,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}