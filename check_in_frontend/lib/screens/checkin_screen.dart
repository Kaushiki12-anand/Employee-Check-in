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
        SnackBar(content: Text('Failed to load check-in history: ${e.toString()}')),
      );
    }
  }

  void _requestCheckin() async {
    try {
      if (kDebugMode) {
        print('Requesting check-in for location: ${widget.location.id}');
      }
      final approved = await _checkinService.requestCheckin(widget.token, widget.location.id);
      if (kDebugMode) {
        print('Check-in request response: $approved');
      }
      if (approved) {
        if (kDebugMode) {
          print('Check-in approved, proceeding to perform check-in');
        }
        _performCheckin();
      } else {
        if (kDebugMode) {
          print('Check-in not approved');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authorized in this location')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Check-in request error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in request failed: ${e.toString()}')),
      );
    }
  }


  void _performCheckin() {
    try {
      _actualPerformCheckin();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Unexpected error during check-in: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred during check-in.')),
      );
    }
  }

  Future<void> _actualPerformCheckin() async {
    try {
      if (kDebugMode) {
        print('Performing check-in');
      }
      if (kDebugMode) {
        print('Checking location permission');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('Location permission denied, requesting permission');
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
        );
        return;
      }

      if (kDebugMode) {
        print('Location permission granted, getting current position');
      }
      final position = await Geolocator.getCurrentPosition();
      if (kDebugMode) {
        print('Current position: ${position.latitude}, ${position.longitude}');
      }

      if (kDebugMode) {
        print('Calling check-in service');
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
      if (e.toString().contains('Out of range')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are too far from the check-in location. Please move closer and try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: ${e.toString()}')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: Column(
        children: [
          Text('Location: ${widget.location.name}'),
          ElevatedButton(
            onPressed: _requestCheckin,
            child: const Text('Check-in'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _checkinHistory.length,
              itemBuilder: (context, index) {
                final checkin = _checkinHistory[index];
                return ListTile(
                  title: Text(checkin.locationName),
                  subtitle: Text(checkin.checkinTime.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}