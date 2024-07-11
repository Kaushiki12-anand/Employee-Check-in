import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location.dart';
import '../models/checkin.dart';
import '../services/checkin_services.dart';

class CheckinScreen extends StatefulWidget {
  final String token;
  final Location location;

  const CheckinScreen({super.key, required this.token, required this.location});

  @override
  _CheckinScreenState createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _checkinService = CheckinService();
  List<Checkin> _checkinHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCheckinHistory();
  }

  void _loadCheckinHistory() async {
    try {
      final history = await _checkinService.getCheckinHistory(widget.token);
      setState(() {
        _checkinHistory = history;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load check-in history: ${e.toString()}')),
      );
    }
  }

  bool _isLoading = false;

  void _requestCheckin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final approved = await _checkinService.requestCheckin(
          widget.token, widget.location.id);
      if (approved) {
        await _performCheckin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authorized in this location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in request failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performCheckin() async {
    try {
      if (kDebugMode) {
        print('Performing check-in');
      }

      bool hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Location permission not granted');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (kDebugMode) {
        print('Current position: ${position.latitude}, ${position.longitude}');
      }

      await _checkinService.checkin(
        widget.token,
        widget.location.id,
        position.latitude,
        position.longitude,
      );

      if (kDebugMode) {
        print('Check-in successful');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in successful')),
      );
      _loadCheckinHistory();
    } catch (e) {
      if (kDebugMode) {
        print('Check-in failed: $e');
      }
      if (e is TimeoutException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Location retrieval timed out. Please try again.')),
        );
      } else if (e.toString().contains('Out of range')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'You are too far from the check-in location. Please move closer and try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Location services are disabled. Please enable the services'),
      ));
      // Open location settings
      await Geolocator.openLocationSettings();
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Location permissions are permanently denied, we cannot request permissions.'),
      ));
      // Open app settings
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.location.name),
              background: Image.network(
                'https://th.bing.com/th/id/R.3afdb29c885b5d855966ed9885e2d180?rik=QPq2VtJP2Xif4g&riu=http%3a%2f%2fwallpapercave.com%2fwp%2fymlhNYY.jpg&ehk=8Qey47EArJaJvQYcETSLn0eOG2tYduUc5dO8GzoG%2brE%3d&risl=&pid=ImgRaw&r=0',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.location_on),
                    label: const Text('Check-in Now'),
                    onPressed: _isLoading ? null : _requestCheckin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const Text(
                    'Check-in History',
                  ),
                ],
              ),
            ),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final checkin = _checkinHistory[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.check, color: Colors.white),
                          ),
                          title: Text(checkin.locationName),
                          subtitle: Text(
                            _formatDateTime(checkin.checkinTime),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                        ),
                      );
                    },
                    childCount: _checkinHistory.length,
                  ),
                ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
