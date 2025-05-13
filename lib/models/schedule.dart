import 'package:intl/intl.dart';

class Schedule {
  final String id;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final String classId;
  final String className;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String roomNumber;

  Schedule({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.className,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      subjectId: map['subjectId'],
      subjectName: map['subjectName'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      classId: map['classId'],
      className: map['className'],
      dayOfWeek: map['dayOfWeek'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      roomNumber: map['roomNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classId': classId,
      'className': className,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'roomNumber': roomNumber,
    };
  }

  String get formattedTimeRange {
    return '$startTime - $endTime';
  }
}
