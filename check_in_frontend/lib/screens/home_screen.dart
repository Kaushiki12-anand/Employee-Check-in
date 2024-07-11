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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Available Locations'),
              background: Image.network(
                'https://th.bing.com/th/id/R.4ffcc6fd5617670101b6bf34bf0a77a6?rik=z9Zr0D2vvugHKg&riu=http%3a%2f%2fwww.montgomerycountymd.gov%2fBiz-Resources%2fResources%2fImages%2ficons%2fPageIcontop5.png&ehk=qOWKFgcjsat%2fP9hgeOVpdwXvI6kaP7rbxRA2KPiGg20%3d&risl=&pid=ImgRaw&r=0',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? _buildErrorWidget()
                      : _locations.isEmpty
                          ? const Center(child: Text('No locations available'))
                          : Text(
                              'Select a location to check-in:',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
            ),
          ),
          _isLoading || _error.isNotEmpty || _locations.isEmpty
              ? const SliverToBoxAdapter(child: SizedBox())
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final location = _locations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.location_on,
                                color: Colors.white),
                          ),
                          title: Text(location.name),
                          trailing: const Icon(Icons.arrow_forward_ios),
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
                        ),
                      );
                    },
                    childCount: _locations.length,
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadLocations,
        tooltip: 'Refresh locations',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error loading locations',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLocations,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
