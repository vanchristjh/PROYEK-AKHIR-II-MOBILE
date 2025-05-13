import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../models/user.dart';
import '../../../models/attendance.dart';
import '../../../services/attendance_service.dart';
import '../../../widgets/loading_indicator.dart';

class TeacherAttendanceTab extends StatefulWidget {
  final User user;
  
  const TeacherAttendanceTab({
    super.key,
    required this.user,
  });

  @override
  State<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<TeacherAttendanceTab> {
  final _attendanceService = MockAttendanceService();
  bool _isLoading = false;
  String? _error;
  
  // Calendar variables
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // Class selection
  final List<String> _classes = ['class-10a', 'class-10b', 'class-11a', 'class-11b'];
  String _selectedClass = 'class-10a';
  
  // Attendance records for the selected class on the selected day
  List<Attendance> _classAttendance = [];
  
  @override
  void initState() {
    super.initState();
    _loadClassAttendance();
  }
  
  Future<void> _loadClassAttendance() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Load attendance for the selected class on the selected date
      final attendance = await _attendanceService.getClassAttendance(
        _selectedClass,
        _selectedDay,
      );
      
      if (mounted) {
        setState(() {
          _classAttendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load attendance: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Update attendance status for a specific student
  Future<void> _updateAttendanceStatus(Attendance attendance, AttendanceStatus newStatus) async {
    try {
      final updatedAttendance = Attendance(
        id: attendance.id,
        userId: attendance.userId,
        userName: attendance.userName,
        date: attendance.date,
        status: newStatus,
        note: attendance.note,
      );
      
      final success = await _attendanceService.recordAttendance(updatedAttendance);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status kehadiran berhasil diperbarui')),
          );
          _loadClassAttendance();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui status kehadiran'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class selection dropdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('Pilih Kelas:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedClass = value;
                          });
                          _loadClassAttendance();
                        }
                      },
                      items: _classes.map((className) {
                        return DropdownMenuItem<String>(
                          value: className,
                          child: Text(className),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadClassAttendance();
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Selected day title
          Text(
            'Absensi Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDay)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Students attendance list
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _error != null
                    ? Center(
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
                              onPressed: _loadClassAttendance,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : _classAttendance.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Tidak ada data kehadiran untuk kelas ini pada tanggal yang dipilih',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadClassAttendance,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _classAttendance.length,
                            itemBuilder: (context, index) {
                              final attendance = _classAttendance[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              attendance.userName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text('ID: ${attendance.userId}'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: DropdownButton<AttendanceStatus>(
                                          value: attendance.status,
                                          isExpanded: true,
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              _updateAttendanceStatus(attendance, newStatus);
                                            }
                                          },
                                          items: AttendanceStatus.values.map((status) {
                                            String label;
                                            Color color;
                                            
                                            switch (status) {
                                              case AttendanceStatus.present:
                                                label = 'Hadir';
                                                color = Colors.green;
                                                break;
                                              case AttendanceStatus.absent:
                                                label = 'Tidak Hadir';
                                                color = Colors.red;
                                                break;
                                              case AttendanceStatus.late:
                                                label = 'Terlambat';
                                                color = Colors.orange;
                                                break;
                                              case AttendanceStatus.excused:
                                                label = 'Izin';
                                                color = Colors.blue;
                                                break;
                                            }
                                            
                                            return DropdownMenuItem<AttendanceStatus>(
                                              value: status,
                                              child: Text(
                                                label,
                                                style: TextStyle(color: color),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
