import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/schedule.dart';
import '../../../services/schedule_service.dart';
import '../../../widgets/loading_indicator.dart';

class TeacherScheduleTab extends StatefulWidget {
  final User user;
  
  const TeacherScheduleTab({
    super.key,
    required this.user,
  });

  @override
  State<TeacherScheduleTab> createState() => _TeacherScheduleTabState();
}

class _TeacherScheduleTabState extends State<TeacherScheduleTab> with SingleTickerProviderStateMixin {
  final _scheduleService = MockScheduleService();
  List<Schedule> _schedules = [];
  bool _isLoading = true;
  String? _error;
  
  final List<String> _daysOfWeek = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _daysOfWeek.length, vsync: this);
    
    // Set initial tab to current day of week (Monday = 0, Sunday = 6)
    final today = DateTime.now().weekday;
    if (today <= 6) { // 1-6 (Monday to Saturday)
      _tabController.index = today - 1;
    }
    
    _loadSchedules();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSchedules() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Get teacher schedules using their ID
      final schedules = await _scheduleService.getTeacherSchedule(widget.user.id);
      
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load schedules: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  // Get schedules for a specific day
  List<Schedule> _getSchedulesForDay(String day) {
    return _schedules
        .where((schedule) => schedule.dayOfWeek == day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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
              onPressed: _loadSchedules,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    if (_schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tidak ada jadwal mengajar tersedia',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSchedules,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: _daysOfWeek.map((day) => Tab(text: day)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _daysOfWeek.map((day) {
              final daySchedules = _getSchedulesForDay(day);
              
              if (daySchedules.isEmpty) {
                return const Center(
                  child: Text('Tidak ada jadwal mengajar untuk hari ini'),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: daySchedules.length,
                itemBuilder: (context, index) {
                  final schedule = daySchedules[index];
                  return _buildScheduleCard(schedule);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildScheduleCard(Schedule schedule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  schedule.subjectName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    schedule.formattedTimeRange,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.class_, 'Kelas: ${schedule.className}'),
            _buildInfoRow(Icons.room, 'Ruangan: ${schedule.roomNumber}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}
