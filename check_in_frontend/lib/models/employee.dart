class Employee {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String grade;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.grade,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      grade: json['grade'],
    );
  }
}