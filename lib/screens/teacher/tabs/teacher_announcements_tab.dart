import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';
import '../../../widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import '../../announcement_detail_screen.dart';

class TeacherAnnouncementsTab extends StatefulWidget {
  final User user;
  
  const TeacherAnnouncementsTab({
    super.key,
    required this.user,
  });

  @override
  State<TeacherAnnouncementsTab> createState() => _TeacherAnnouncementsTabState();
}

class _TeacherAnnouncementsTabState extends State<TeacherAnnouncementsTab> {
  final _announcementService = MockAnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error;
  
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  
  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }
  
  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final announcements = await _announcementService.getUserAnnouncements(
        widget.user.id,
        'teacher',
        null, // Teachers don't have classId
      );
      
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load announcements: $e';
          _isLoading = false;
        });
      }
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
              onPressed: _loadAnnouncements,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tidak ada pengumuman saat ini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            child: ListTile(
              title: Text(
                announcement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Dari: ${announcement.authorName}'),
                  Text('Tanggal: ${_dateFormat.format(announcement.publishDate)}'),
                  const SizedBox(height: 8),
                  Text(
                    announcement.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.all(16),
              onTap: () {
                _showAnnouncementDetails(announcement);
              },
            ),
          );
        },
      ),
    );
  }
  
  void _showAnnouncementDetails(Announcement announcement) {
    // Navigate to the detailed announcement screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(announcement: announcement),
      ),
    );
  }
}
