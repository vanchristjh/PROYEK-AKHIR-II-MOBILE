enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class Attendance {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  Attendance({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.status,
    this.note,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values.firstWhere(
        (status) => status.toString() == 'AttendanceStatus.${map['status']}',
      ),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'note': note,
    };
  }
}