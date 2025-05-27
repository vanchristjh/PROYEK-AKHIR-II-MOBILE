import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../models/user.dart';
import '../../../models/attendance.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/loading_indicator.dart';

class StudentAttendanceTab extends StatefulWidget {
  final User user;
  
  const StudentAttendanceTab({
    super.key,
    required this.user,
  });

  @override
  State<StudentAttendanceTab> createState() => _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends State<StudentAttendanceTab> {
  final _attendanceService = MockAttendanceService();
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;
  String? _error;
  
  // Calendar variables
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Statistics
  int _totalPresent = 0;
  int _totalAbsent = 0;
  int _totalLate = 0;
  int _totalExcused = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }
  
  Future<void> _loadAttendance() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final records = await _attendanceService.getUserAttendance(widget.user.id);
      
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
          _calculateStatistics();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load attendance records: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _calculateStatistics() {
    _totalPresent = _attendanceRecords.where((a) => a.status == AttendanceStatus.present).length;
    _totalAbsent = _attendanceRecords.where((a) => a.status == AttendanceStatus.absent).length;
    _totalLate = _attendanceRecords.where((a) => a.status == AttendanceStatus.late).length;
    _totalExcused = _attendanceRecords.where((a) => a.status == AttendanceStatus.excused).length;
  }
  
  // Get attendance event for the selected day
  Attendance? _getAttendanceForDay(DateTime day) {
    return _attendanceRecords.firstWhere(
      (record) => 
          record.date.year == day.year && 
          record.date.month == day.month && 
          record.date.day == day.day,
      orElse: () => Attendance(
        id: 'temp',
        userId: widget.user.id,
        userName: widget.user.name,
        date: day,
        status: AttendanceStatus.absent,
        note: 'Not recorded yet',
      ),
    );
  }
  
  // Get color for the calendar event based on attendance status
  Color _getEventColor(Attendance? attendance) {
    if (attendance == null) return Colors.transparent;
    
    switch (attendance.status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return Colors.blue;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttendance,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final attendance = _attendanceRecords.where((a) => 
                a.date.year == day.year && 
                a.date.month == day.month && 
                a.date.day == day.day
              ).toList();
              return attendance;
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final attendance = events.first as Attendance;
                  return Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEventColor(attendance),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistik Kehadiran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Hadir', _totalPresent, Colors.green),
                      _buildStatItem('Terlambat', _totalLate, Colors.orange),
                      _buildStatItem('Absen', _totalAbsent, Colors.red),
                      _buildStatItem('Izin', _totalExcused, Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Selected day attendance details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail Kehadiran: ${DateFormat('dd MMM yyyy').format(_selectedDay)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAttendanceDetails(_getAttendanceForDay(_selectedDay)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
  
  Widget _buildAttendanceDetails(Attendance? attendance) {
    if (attendance == null) {
      return const Text('Tidak ada data kehadiran untuk hari ini');
    }
    
    String statusText;
    Color statusColor;
    
    switch (attendance.status) {
      case AttendanceStatus.present:
        statusText = 'Hadir';
        statusColor = Colors.green;
        break;
      case AttendanceStatus.absent:
        statusText = 'Tidak Hadir';
        statusColor = Colors.red;
        break;
      case AttendanceStatus.late:
        statusText = 'Terlambat';
        statusColor = Colors.orange;
        break;
      case AttendanceStatus.excused:
        statusText = 'Izin';
        statusColor = Colors.blue;
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Status: '),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (attendance.note != null && attendance.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Catatan: ${attendance.note}'),
          ),
      ],
    );
  }
}