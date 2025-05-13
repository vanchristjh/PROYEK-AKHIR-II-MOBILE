import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;
  
  const AnnouncementDetailScreen({super.key, required this.announcement});
  
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
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pengumuman', 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: _getAnnouncementColor(announcement.type).withOpacity(0.7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getAnnouncementColor(announcement.type).withOpacity(0.7),
                    _getAnnouncementColor(announcement.type).withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getAnnouncementColor(announcement.type),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getAnnouncementTypeText(announcement.type),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    announcement.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Author and date
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        announcement.authorName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(announcement.publishDate),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  // Expiry date if available
                  if (announcement.expiryDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_off, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Berakhir: ${dateFormat.format(announcement.expiryDate!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target audience section
                  Text(
                    'Target Audience:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTargetAudienceChips(context, announcement.targetAudience),
                  
                  const SizedBox(height: 24),
                  
                  // Content section
                  Text(
                    'Content:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      announcement.content,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTargetAudienceChips(BuildContext context, List<String> targetAudience) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: targetAudience.map((target) {
        IconData icon;
        String label;
        Color color;
        
        if (target == 'all') {
          icon = Icons.public;
          label = 'Semua';
          color = Theme.of(context).colorScheme.primary;
        } else if (target == 'teacher' || target == 'teachers') {
          icon = Icons.school;
          label = 'Guru';
          color = Colors.green;
        } else if (target == 'student' || target == 'students') {
          icon = Icons.person;
          label = 'Siswa';
          color = Colors.orange;
        } else if (target.startsWith('class-') || target.startsWith('class_')) {
          icon = Icons.group;
          final className = target.contains('-') 
              ? target.replaceFirst('class-', 'Kelas ')
              : target.replaceFirst('class_', 'Kelas ');
          label = className;
          color = Colors.purple;
        } else {
          icon = Icons.group;
          label = target;
          color = Colors.grey;
        }
        
        return Chip(
          avatar: Icon(icon, size: 16, color: Colors.white),
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
          backgroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
  
  String _formatAudienceLabel(String audience) {
    switch (audience) {
      case 'all':
        return 'Everyone';
      case 'teacher':
        return 'Teachers';
      case 'student':
        return 'Students';
      default:
        if (audience.startsWith('class-')) {
          return audience.replaceFirst('class-', 'Class ');
        }
        return audience;
    }
  }
}
