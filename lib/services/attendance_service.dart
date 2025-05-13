import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fetch attendance records for a specific user
  Future<List<Attendance>> getUserAttendance(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Attendance.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user attendance: $e');
      return [];
    }
  }
  
  // Record a new attendance entry
  Future<bool> recordAttendance(Attendance attendance) async {
    try {
      // Check if attendance for this user on this date already exists
      final existingRecord = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: attendance.userId)
          .where('date', isEqualTo: attendance.date)
          .get();
          
      if (existingRecord.docs.isNotEmpty) {
        // Update existing record
        await _firestore
            .collection('attendance')
            .doc(existingRecord.docs.first.id)
            .update(attendance.toMap());
      } else {
        // Create new record
        await _firestore
            .collection('attendance')
            .add(attendance.toMap());
      }
      return true;
    } catch (e) {
      debugPrint('Error recording attendance: $e');
      return false;
    }
  }
  
  // Get class attendance for a specific day
  Future<List<Attendance>> getClassAttendance(String classId, DateTime date) async {
    try {
      // First get all students in this class
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('classId', isEqualTo: classId)
          .where('role', isEqualTo: 'student')
          .get();
          
      final studentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();
      
      // Then get attendance records for these students on the specified date
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('userId', whereIn: studentIds)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThanOrEqualTo: endOfDay)
          .get();
          
      return attendanceSnapshot.docs.map((doc) {
        final data = doc.data();
        return Attendance.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching class attendance: $e');
      return [];
    }
  }
}

// Mock implementation for testing/development without Firebase
class MockAttendanceService {
  final List<Attendance> _mockAttendance = [];
  
  MockAttendanceService() {
    // Initialize with some mock data
    final now = DateTime.now();
    
    // Mock data for a student
    _mockAttendance.addAll([
      Attendance(
        id: '1',
        userId: 'student1',
        userName: 'Murid Demo',
        date: DateTime(now.year, now.month, now.day - 1),
        status: AttendanceStatus.present,
      ),
      Attendance(
        id: '2',
        userId: 'student1',
        userName: 'Murid Demo',
        date: DateTime(now.year, now.month, now.day - 2),
        status: AttendanceStatus.present,
      ),
      Attendance(
        id: '3',
        userId: 'student1',
        userName: 'Murid Demo',
        date: DateTime(now.year, now.month, now.day - 3),
        status: AttendanceStatus.absent,
        note: 'Sick leave',
      ),
    ]);
  }
  
  Future<List<Attendance>> getUserAttendance(String userId) async {
    return _mockAttendance
        .where((record) => record.userId == userId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  Future<bool> recordAttendance(Attendance attendance) async {
    try {
      // Check if attendance already exists for this date and user
      final existingIndex = _mockAttendance.indexWhere(
        (a) => a.userId == attendance.userId && 
              a.date.year == attendance.date.year &&
              a.date.month == attendance.date.month &&
              a.date.day == attendance.date.day
      );
      
      if (existingIndex >= 0) {
        // Update existing
        _mockAttendance[existingIndex] = attendance;
      } else {
        // Add new
        _mockAttendance.add(attendance);
      }
      return true;
    } catch (e) {
      debugPrint('Error recording mock attendance: $e');
      return false;
    }
  }
  
  Future<List<Attendance>> getClassAttendance(String classId, DateTime date) async {
    // In a real implementation, we would filter by users with this classId
    // For mock, we'll just return all records for the given date
    return _mockAttendance
        .where((record) => 
            record.date.year == date.year &&
            record.date.month == date.month &&
            record.date.day == date.day)
        .toList();
  }
}
