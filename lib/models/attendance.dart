import 'package:intl/intl.dart';

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
      date: (map['date'] as Timestamp).toDate(),
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
      'date': date,
      'status': status.toString().split('.').last,
      'note': note,
    };
  }

  String get formattedDate {
    return DateFormat('dd MMMM yyyy').format(date);
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

class Timestamp {
  final DateTime _dateTime;
  
  Timestamp(this._dateTime);

  DateTime toDate() => _dateTime;
}
