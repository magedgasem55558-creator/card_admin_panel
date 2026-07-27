class Halaqa {
  final String id;
  final String name;
  final String teacherName;
  final String? teacherPhone;

  Halaqa({
    required this.id,
    required this.name,
    required this.teacherName,
    this.teacherPhone,
  });

  factory Halaqa.fromMap(String id, Map<String, dynamic> data) {
    return Halaqa(
      id: id,
      name: data['name'] ?? '',
      teacherName: data['teacherName'] ?? '',
      teacherPhone: data['teacherPhone'],
    );
  }
}