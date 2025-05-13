import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import '../../../models/user.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';
import '../../../widgets/loading_indicator.dart';
import '../../announcement_detail_screen.dart';

class StudentAnnouncementsTab extends StatefulWidget {
  final User user;
  
  const StudentAnnouncementsTab({
    super.key,
    required this.user,
  });

  @override
  State<StudentAnnouncementsTab> createState() => _StudentAnnouncementsTabState();
}

class _StudentAnnouncementsTabState extends State<StudentAnnouncementsTab> {
  final _announcementService = MockAnnouncementService();  List<Announcement> _announcements = [];
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
        'student',
        widget.user.classId,
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
            Icon(
              Icons.notification_important_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada pengumuman saat ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAnnouncements,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }
      return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      color: Theme.of(context).colorScheme.primary,
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: _announcements.length,
          itemBuilder: (context, index) {
            final announcement = _announcements[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    elevation: 3,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showAnnouncementDetails(announcement),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tags or priority indicator
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getAnnouncementColor(announcement.type),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    _getAnnouncementTypeText(announcement.type),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _dateFormat.format(announcement.publishDate),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Title
                            Text(
                              announcement.title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Author
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  announcement.authorName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Content preview
                            Text(
                              announcement.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Read more button
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _showAnnouncementDetails(announcement),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: Text(
                                  'Baca Selengkapnya',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),            );
          },
        ),
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
  
  // Helper method to get color based on announcement type
  Color _getAnnouncementColor(String type) {
    switch (type.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'important':
        return Colors.orangeAccent;
      case 'academic':
        return Colors.blueAccent;
      case 'event':
        return Colors.greenAccent[700]!;
      default:
        return Colors.blueGrey;
    }
  }
  
  // Helper method to get display text for announcement type
  String _getAnnouncementTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'urgent':
        return 'PENTING SEGERA';
      case 'important':
        return 'PENTING';
      case 'academic':
        return 'AKADEMIK';
      case 'event':
        return 'ACARA';
      default:
        return type.toUpperCase();
    }
  }
}
