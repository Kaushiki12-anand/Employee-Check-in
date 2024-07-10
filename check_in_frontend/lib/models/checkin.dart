class Checkin {
  final DateTime checkinTime;
  final String locationName;

  Checkin({
    required this.checkinTime,
    required this.locationName,
  });

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      checkinTime: DateTime.parse(json['checkin_time']),
      locationName: json['location_name'],
    );
  }
}