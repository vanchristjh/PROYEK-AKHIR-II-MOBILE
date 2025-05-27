import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<List<Announcement>> getUserAnnouncements(String userId, String? userRole, String? classId) async {
    try {
      final allAnnouncementsQuery = _firestore
          .collection('announcements')
          .where('targetAudience', arrayContains: 'all')
          .orderBy('publishDate', descending: true);

      final allAnnouncementsSnapshot = await allAnnouncementsQuery.get();

      final roleAnnouncementsQuery = _firestore
          .collection('announcements')
          .where('targetAudience', arrayContains: userRole ?? '')
          .orderBy('publishDate', descending: true);

      final roleAnnouncementsSnapshot = await roleAnnouncementsQuery.get();

      List<QueryDocumentSnapshot> classAnnouncementsDocs = [];
      if (userRole == 'student' && classId != null) {
        final classAnnouncementsQuery = _firestore
            .collection('announcements')
            .where('targetAudience', arrayContains: classId)
            .orderBy('publishDate', descending: true);

        final classAnnouncementsSnapshot = await classAnnouncementsQuery.get();
        classAnnouncementsDocs = classAnnouncementsSnapshot.docs;
      }

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

  Future<bool> addAnnouncement(Announcement announcement) async {
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

class MockAnnouncementService {
  final List<Announcement> _mockAnnouncements = [];

  MockAnnouncementService() {
    // Sesuaikan dengan tanggal saat ini: 27 Mei 2025, 17:24 WIB
    _mockAnnouncements.addAll([
      Announcement(
        id: '1',
        title: 'Pengumuman Ujian Semester',
        content: 'Ujian semester akan dilaksanakan pada tanggal 15-20 Juni 2025. Harap semua siswa mempersiapkan diri dengan baik.',
        publishDate: DateTime(2025, 5, 27, 14, 0), // 27 Mei 2025, 14:00 WIB (beberapa jam sebelum waktu saat ini)
        authorId: 'admin1',
        authorName: 'Admin Sekolah',
        type: 'academic',
        targetAudience: ['all'],
        expiryDate: DateTime(2025, 6, 20, 23, 59), // Belum kedaluwarsa
      ),
      Announcement(
        id: '2',
        title: 'Rapat Guru',
        content: 'Diberitahukan kepada semua guru untuk menghadiri rapat pada hari Senin, 20 Mei 2025 pukul 14.00 WIB di Ruang Rapat.',
        publishDate: DateTime(2025, 5, 20, 14, 0), // 20 Mei 2025, 14:00 WIB
        authorId: 'admin1',
        authorName: 'Admin Sekolah',
        type: 'event',
        targetAudience: ['teacher'],
        expiryDate: DateTime(2025, 5, 21, 23, 59), // Sudah kedaluwarsa (sebelum 27 Mei 2025)
      ),
      Announcement(
        id: '3',
        title: 'Perubahan Jadwal Kelas 10A',
        content: 'Diberitahukan kepada siswa kelas 10A bahwa jadwal pelajaran matematika pada hari Rabu dipindahkan ke hari Kamis.',
        publishDate: DateTime(2025, 5, 10, 8, 0), // 10 Mei 2025, 08:00 WIB
        authorId: 'teacher1',
        authorName: 'Guru Demo',
        type: 'academic',
        targetAudience: ['class-10a'],
        expiryDate: null, // Tidak ada expiry date
      ),
      // Tambah pengumuman baru yang dipublikasikan hari ini
      Announcement(
        id: '4',
        title: 'Pengumuman Libur Sekolah',
        content: 'Sekolah akan libur pada tanggal 28 Mei 2025 untuk memperingati hari besar.',
        publishDate: DateTime(2025, 5, 27, 17, 0), // 27 Mei 2025, 17:00 WIB (beberapa menit sebelum waktu saat ini)
        authorId: 'admin1',
        authorName: 'Admin Sekolah',
        type: 'event',
        targetAudience: ['all'],
        expiryDate: DateTime(2025, 5, 28, 23, 59), // Kedaluwarsa besok malam
      ),
    ]);
  }

  Future<List<Announcement>> getAllAnnouncements() async {
    return List<Announcement>.from(_mockAnnouncements)
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  Future<List<Announcement>> getUserAnnouncements(String userId, String? userRole, String? classId) async {
    if (userRole == 'admin') {
      return getAllAnnouncements();
    }

    List<Announcement> relevantAnnouncements = [];

    for (final announcement in _mockAnnouncements) {
      final targets = announcement.targetAudience;
      if (targets != null && (
          targets.contains('all') ||
          (userRole != null && targets.contains(userRole.toLowerCase())) ||
          (classId != null && targets.contains(classId.toLowerCase())))) {
        relevantAnnouncements.add(announcement);
      }
    }

    final now = DateTime.now();
    return relevantAnnouncements
        .where((a) => a.expiryDate == null || a.expiryDate!.isAfter(now))
        .toList()
      ..sort((a, b) => b.publishDate.compareTo(a.publishDate));
  }

  Future<bool> addAnnouncement(Announcement announcement) async {
    try {
      _mockAnnouncements.add(announcement);
      return true;
    } catch (e) {
      debugPrint('Error creating mock announcement: $e');
      return false;
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