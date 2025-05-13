import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fetch all announcements (for admin)
  Future<List<Announcement>> getAllAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('publishDate', descending: true)
          .get();
          
      return snapshot.docs.map((doc) {
        return Announcement.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching all announcements: $e');
      return [];
    }
  }
  
  // Fetch announcements relevant to a specific user
  Future<List<Announcement>> getUserAnnouncements(String userId, String? userRole, String? classId) async {
    try {
      // First, get announcements for everyone
      final allAnnouncementsQuery = _firestore
          .collection('announcements')
          .where('targetAudience', arrayContains: 'all')
          .orderBy('publishDate', descending: true);
          
      final allAnnouncementsSnapshot = await allAnnouncementsQuery.get();
      
      // Next, get role-specific announcements
      final roleAnnouncementsQuery = _firestore
          .collection('announcements')
          .where('targetAudience', arrayContains: userRole)
          .orderBy('publishDate', descending: true);
          
      final roleAnnouncementsSnapshot = await roleAnnouncementsQuery.get();
      
      // For students, also get class-specific announcements
      List<QueryDocumentSnapshot> classAnnouncementsDocs = [];
      if (userRole == 'student' && classId != null) {
        final classAnnouncementsQuery = _firestore
            .collection('announcements')
            .where('targetAudience', arrayContains: classId)
            .orderBy('publishDate', descending: true);
            
        final classAnnouncementsSnapshot = await classAnnouncementsQuery.get();
        classAnnouncementsDocs = classAnnouncementsSnapshot.docs;
      }
      
      // Combine all announcements and remove duplicates
      final Set<String> processedIds = {};
      final List<Announcement> announcements = [];
      
      for (final doc in [...allAnnouncementsSnapshot.docs, ...roleAnnouncementsSnapshot.docs, ...classAnnouncementsDocs]) {
        if (processedIds.contains(doc.id)) continue;
        
        processedIds.add(doc.id);
        final data = doc.data() as Map<String, dynamic>;
        
        announcements.add(Announcement.fromMap({
          'id': doc.id,
          ...data,
        }));
      }
      
      // Filter out expired announcements
      final now = DateTime.now();
      return announcements
          .where((a) => a.expiryDate == null || a.expiryDate!.isAfter(now))
          .toList()
        ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      return [];
    }
  }
  
  // Create a new announcement
  Future<bool> createAnnouncement(Announcement announcement) async {
    try {
      await _firestore
          .collection('announcements')
          .add(announcement.toMap());
      return true;
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      return false;
    }
  }
  
  // Update an existing announcement
  Future<bool> updateAnnouncement(Announcement announcement) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcement.id)
          .update(announcement.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating announcement: $e');
      return false;
    }
  }
  
  // Delete an announcement
  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(announcementId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      return false;
    }
  }
}

// Mock implementation for testing/development without Firebase
class MockAnnouncementService {
  final List<Announcement> _mockAnnouncements = [];
  
  MockAnnouncementService() {
    // Initialize with some mock data
    final now = DateTime.now();
    
    _mockAnnouncements.addAll([
      Announcement(
        id: '1',
        title: 'Pengumuman Ujian Semester',
        content: 'Ujian semester akan dilaksanakan pada tanggal 15-20 Juni 2025. Harap semua siswa mempersiapkan diri dengan baik.',
        publishDate: DateTime(now.year, now.month - 1, 15),
        authorId: 'admin1',
        authorName: 'Admin Sekolah',
        targetAudience: ['all'],
      ),
      Announcement(
        id: '2',
        title: 'Rapat Guru',
        content: 'Diberitahukan kepada semua guru untuk menghadiri rapat pada hari Senin, 20 Mei 2025 pukul 14.00 WIB di Ruang Rapat.',
        publishDate: DateTime(now.year, now.month, 5),
        authorId: 'admin1',
        authorName: 'Admin Sekolah',
        targetAudience: ['teacher'],
      ),
      Announcement(
        id: '3',
        title: 'Perubahan Jadwal Kelas 10A',
        content: 'Diberitahukan kepada siswa kelas 10A bahwa jadwal pelajaran matematika pada hari Rabu dipindahkan ke hari Kamis.',
        publishDate: DateTime(now.year, now.month, 10),
        authorId: 'teacher1',
        authorName: 'Guru Demo',
        targetAudience: ['class-10a'],
      ),
    ]);
  }
    // Get all announcements (for admin)
  Future<List<Announcement>> getAllAnnouncements() async {
    // Return a copy of all announcements
    return List<Announcement>.from(_mockAnnouncements)
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }
  
  Future<List<Announcement>> getUserAnnouncements(String userId, String? userRole, String? classId) async {
    // For admin, return all announcements
    if (userRole == 'admin') {
      return getAllAnnouncements();
    }
    
    List<Announcement> relevantAnnouncements = [];
    
    for (final announcement in _mockAnnouncements) {
      final targets = announcement.targetAudience;
      
      if (targets.contains('all') || 
          (userRole != null && targets.contains(userRole)) ||
          (classId != null && targets.contains(classId))) {
        relevantAnnouncements.add(announcement);
      }
    }
    
    // Filter out expired announcements
    final now = DateTime.now();
    return relevantAnnouncements
        .where((a) => a.expiryDate == null || a.expiryDate!.isAfter(now))
        .toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }
  Future<bool> createAnnouncement(Announcement announcement) async {
    try {
      _mockAnnouncements.add(announcement);
      return true; // Return true on success
    } catch (e) {
      debugPrint('Error creating mock announcement: $e');
      return false; // Return false on failure
    }
  }
  
  Future<bool> updateAnnouncement(Announcement announcement) async {
    try {
      final index = _mockAnnouncements.indexWhere((a) => a.id == announcement.id);
      if (index >= 0) {
        _mockAnnouncements[index] = announcement;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating mock announcement: $e');
      return false;
    }
  }
  
  Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      _mockAnnouncements.removeWhere((a) => a.id == announcementId);
      return true;
    } catch (e) {
      debugPrint('Error deleting mock announcement: $e');
      return false;
    }
  }
}
