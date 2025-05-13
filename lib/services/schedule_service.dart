import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fetch schedules for a specific class
  Future<List<Schedule>> getClassSchedule(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('classId', isEqualTo: classId)
          .get();
          
      return snapshot.docs.map((doc) {
        return Schedule.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList()
        ..sort((a, b) {
          // Sort by day of week first
          final daysOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
          final dayCompare = daysOrder.indexOf(a.dayOfWeek) - daysOrder.indexOf(b.dayOfWeek);
          
          if (dayCompare != 0) return dayCompare;
          
          // Then sort by start time
          return a.startTime.compareTo(b.startTime);
        });
    } catch (e) {
      debugPrint('Error fetching class schedules: $e');
      return [];
    }
  }
  
  // Fetch schedules for a specific teacher
  Future<List<Schedule>> getTeacherSchedule(String teacherId) async {
    try {
      final snapshot = await _firestore
          .collection('schedules')
          .where('teacherId', isEqualTo: teacherId)
          .get();
          
      return snapshot.docs.map((doc) {
        return Schedule.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList()
        ..sort((a, b) {
          // Sort by day of week first
          final daysOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
          final dayCompare = daysOrder.indexOf(a.dayOfWeek) - daysOrder.indexOf(b.dayOfWeek);
          
          if (dayCompare != 0) return dayCompare;
          
          // Then sort by start time
          return a.startTime.compareTo(b.startTime);
        });
    } catch (e) {
      debugPrint('Error fetching teacher schedules: $e');
      return [];
    }
  }
  
  // Create a new schedule
  Future<bool> createSchedule(Schedule schedule) async {
    try {
      // Check for conflicts
      if (await _hasScheduleConflict(schedule)) {
        return false;
      }
      
      await _firestore
          .collection('schedules')
          .add(schedule.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating schedule: $e');
      return false;
    }
  }
  
  // Update an existing schedule
  Future<bool> updateSchedule(Schedule schedule) async {
    try {
      // Check for conflicts (excluding this schedule)
      if (await _hasScheduleConflict(schedule, excludeId: schedule.id)) {
        return false;
      }
      
      await _firestore
          .collection('schedules')
          .doc(schedule.id)
          .update(schedule.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating schedule: $e');
      return false;
    }
  }
  
  // Delete a schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _firestore
          .collection('schedules')
          .doc(scheduleId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      return false;
    }
  }
  
  // Helper method to check for schedule conflicts
  Future<bool> _hasScheduleConflict(Schedule newSchedule, {String? excludeId}) async {
    try {
      // Check for class conflicts (same class, same day, overlapping time)
      final classConflictQuery = await _firestore
          .collection('schedules')
          .where('classId', isEqualTo: newSchedule.classId)
          .where('dayOfWeek', isEqualTo: newSchedule.dayOfWeek)
          .get();
          
      // Check for teacher conflicts (same teacher, same day, overlapping time)
      final teacherConflictQuery = await _firestore
          .collection('schedules')
          .where('teacherId', isEqualTo: newSchedule.teacherId)
          .where('dayOfWeek', isEqualTo: newSchedule.dayOfWeek)
          .get();
          
      // Room conflicts (same room, same day, overlapping time)
      final roomConflictQuery = await _firestore
          .collection('schedules')
          .where('roomNumber', isEqualTo: newSchedule.roomNumber)
          .where('dayOfWeek', isEqualTo: newSchedule.dayOfWeek)
          .get();
          
      // Combine all potential conflicts
      final allPotentialConflicts = [
        ...classConflictQuery.docs,
        ...teacherConflictQuery.docs,
        ...roomConflictQuery.docs,
      ];
      
      // Check for actual time conflicts
      for (final doc in allPotentialConflicts) {
        // Skip if this is the schedule we're updating
        if (excludeId != null && doc.id == excludeId) continue;
        
        final existingSchedule = Schedule.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
        
        // Check for time overlap
        if (_hasTimeOverlap(
          newSchedule.startTime, 
          newSchedule.endTime,
          existingSchedule.startTime,
          existingSchedule.endTime
        )) {
          return true; // Conflict found
        }
      }
      
      return false; // No conflict
    } catch (e) {
      debugPrint('Error checking schedule conflicts: $e');
      return true; // Assume conflict if error
    }
  }
  
  // Helper to check if two time ranges overlap
  bool _hasTimeOverlap(String start1, String end1, String start2, String end2) {
    // Convert times to comparable values (e.g., minutes since midnight)
    final timeToMinutes = (String time) {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    };
    
    final start1Minutes = timeToMinutes(start1);
    final end1Minutes = timeToMinutes(end1);
    final start2Minutes = timeToMinutes(start2);
    final end2Minutes = timeToMinutes(end2);
    
    // Check for overlap
    if (start1Minutes >= end2Minutes || end1Minutes <= start2Minutes) {
      return false; // No overlap
    }
    return true; // Overlap exists
  }
}

// Mock implementation for testing/development without Firebase
class MockScheduleService {
  final List<Schedule> _mockSchedules = [];
  
  MockScheduleService() {
    // Initialize with some mock data
    _mockSchedules.addAll([
      Schedule(
        id: '1',
        subjectId: 'math',
        subjectName: 'Matematika',
        teacherId: 'teacher1',
        teacherName: 'Guru Demo',
        classId: 'class-10a',
        className: 'Kelas 10A',
        dayOfWeek: 'Senin',
        startTime: '07:30',
        endTime: '09:00',
        roomNumber: '101',
      ),
      Schedule(
        id: '2',
        subjectId: 'science',
        subjectName: 'IPA',
        teacherId: 'teacher1',
        teacherName: 'Guru Demo',
        classId: 'class-10a',
        className: 'Kelas 10A',
        dayOfWeek: 'Selasa',
        startTime: '09:15',
        endTime: '10:45',
        roomNumber: '102',
      ),
      Schedule(
        id: '3',
        subjectId: 'english',
        subjectName: 'Bahasa Inggris',
        teacherId: 'teacher2',
        teacherName: 'Guru Lainnya',
        classId: 'class-10a',
        className: 'Kelas 10A',
        dayOfWeek: 'Rabu',
        startTime: '07:30',
        endTime: '09:00',
        roomNumber: '103',
      ),
    ]);
  }
  
  Future<List<Schedule>> getClassSchedule(String classId) async {
    return _mockSchedules
        .where((schedule) => schedule.classId == classId)
        .toList()
      ..sort((a, b) {
        // Sort by day of week first
        final daysOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        final dayCompare = daysOrder.indexOf(a.dayOfWeek) - daysOrder.indexOf(b.dayOfWeek);
        
        if (dayCompare != 0) return dayCompare;
        
        // Then sort by start time
        return a.startTime.compareTo(b.startTime);
      });
  }
  
  Future<List<Schedule>> getTeacherSchedule(String teacherId) async {
    return _mockSchedules
        .where((schedule) => schedule.teacherId == teacherId)
        .toList()
      ..sort((a, b) {
        // Sort by day of week first
        final daysOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        final dayCompare = daysOrder.indexOf(a.dayOfWeek) - daysOrder.indexOf(b.dayOfWeek);
        
        if (dayCompare != 0) return dayCompare;
        
        // Then sort by start time
        return a.startTime.compareTo(b.startTime);
      });
  }
  
  Future<bool> createSchedule(Schedule schedule) async {
    try {
      // Check for conflicts
      if (_hasScheduleConflict(schedule)) {
        return false;
      }
      
      _mockSchedules.add(schedule);
      return true;
    } catch (e) {
      debugPrint('Error creating mock schedule: $e');
      return false;
    }
  }
  
  Future<bool> updateSchedule(Schedule schedule) async {
    try {
      // Check for conflicts (excluding this schedule)
      if (_hasScheduleConflict(schedule, excludeId: schedule.id)) {
        return false;
      }
      
      final index = _mockSchedules.indexWhere((s) => s.id == schedule.id);
      if (index >= 0) {
        _mockSchedules[index] = schedule;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating mock schedule: $e');
      return false;
    }
  }
  
  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      _mockSchedules.removeWhere((s) => s.id == scheduleId);
      return true;
    } catch (e) {
      debugPrint('Error deleting mock schedule: $e');
      return false;
    }
  }
  
  // Helper method for checking schedule conflicts
  bool _hasScheduleConflict(Schedule newSchedule, {String? excludeId}) {
    for (final existingSchedule in _mockSchedules) {
      // Skip if it's the same schedule
      if (excludeId != null && existingSchedule.id == excludeId) continue;
      
      // Check if same day
      if (existingSchedule.dayOfWeek != newSchedule.dayOfWeek) continue;
      
      // Check for class, teacher, or room conflicts
      final sameClass = existingSchedule.classId == newSchedule.classId;
      final sameTeacher = existingSchedule.teacherId == newSchedule.teacherId;
      final sameRoom = existingSchedule.roomNumber == newSchedule.roomNumber;
      
      if (!(sameClass || sameTeacher || sameRoom)) continue;
      
      // Check for time overlap
      if (_hasTimeOverlap(
        newSchedule.startTime, 
        newSchedule.endTime,
        existingSchedule.startTime,
        existingSchedule.endTime
      )) {
        return true; // Conflict found
      }
    }
    
    return false; // No conflict
  }
  
  // Helper to check if two time ranges overlap
  bool _hasTimeOverlap(String start1, String end1, String start2, String end2) {
    // Convert times to comparable values (e.g., minutes since midnight)
    final timeToMinutes = (String time) {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    };
    
    final start1Minutes = timeToMinutes(start1);
    final end1Minutes = timeToMinutes(end1);
    final start2Minutes = timeToMinutes(start2);
    final end2Minutes = timeToMinutes(end2);
    
    // Check for overlap
    if (start1Minutes >= end2Minutes || end1Minutes <= start2Minutes) {
      return false; // No overlap
    }
    return true; // Overlap exists
  }
}
