import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../models/announcement.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/announcement_service.dart';
import 'teacher/teacher_home_screen.dart'; // Impor hanya dari sini
import 'student/student_home_screen.dart';
import 'login_screen.dart';
import 'admin/admin_user_management_screen.dart';
import 'admin/add_announcement_screen.dart'; // Impor untuk widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MockUserService _userService = MockUserService();
  final MockAnnouncementService _announcementService = MockAnnouncementService();
  List<User> _users = [];
  List<Announcement> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadAnnouncements();
  }

  Future<void> _loadUsers() async {
    final users = await _userService.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _loadAnnouncements() async {
    final user = await Provider.of<MockAuthService>(context, listen: false).currentUser;
    if (user != null) {
      final announcements = await _announcementService.getUserAnnouncements(
        user.id,
        user.role.toString().split('.').last,
        user.classId,
      );
      setState(() {
        _announcements = announcements;
      });
    }
  }

  void _showProfileDialog(MockAuthService authService, UserRole role) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: FutureBuilder<User?>(
          future: authService.currentUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data ??
                User(
                  id: 'unknown_id',
                  name: 'Unknown',
                  email: 'unknown@school.edu',
                  role: role,
                  classId: null,
                  subjectIds: null,
                );
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          role == UserRole.admin ? 'Profil Admin' : 'Profil Guru',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.name[0],
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role == UserRole.admin ? 'Informasi Admin' : 'Informasi Guru',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoItem(
                                  icon: role == UserRole.admin ? Icons.people : Icons.schedule,
                                  label: role == UserRole.admin ? 'Total Users' : 'Total Schedules',
                                  value: role == UserRole.admin ? _users.length.toString() : '10',
                                ),
                                _buildInfoItem(
                                  icon: Icons.admin_panel_settings,
                                  label: 'Role',
                                  value: role == UserRole.admin ? 'Admin' : 'Guru',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                if (role == UserRole.admin) {
                                  Navigator.pushNamed(context, '/admin_user_management');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Navigasi ke Manage Schedule')),
                                  );
                                }
                              },
                              icon: Icon(role == UserRole.admin ? Icons.people : Icons.schedule),
                              label: Text(role == UserRole.admin ? 'Manage Users' : 'Manage Schedule'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                await authService.signOut();
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MockAuthService>(
      builder: (context, authService, child) {
        return FutureBuilder<User?>(
          future: authService.currentUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading user data...',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = snapshot.data;
            if (user == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (user.role == UserRole.admin) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.purple,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang, Admin',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 12,
                            child: Text(
                              user.name[0],
                              style: const TextStyle(color: Colors.purple, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Notifications'),
                            content: const Text('No new notifications.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Terbaru',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _announcements.isEmpty
                            ? Center(
                                child: Text(
                                  'Belum ada pengumuman.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _announcements.length,
                                itemBuilder: (context, index) {
                                  final announcement = _announcements[index];
                                  return Column(
                                    children: [
                                      _buildInfoCard(
                                        title: announcement.title,
                                        date: DateFormat('dd MMMM yyyy, HH:mm').format(announcement.publishDate),
                                        author: announcement.authorName,
                                        content: announcement.content,
                                        type: announcement.type,
                                        targetAudience: announcement.targetAudience,
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Detail: ${announcement.title}')),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin_user_management');
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('Manage Users'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddAnnouncementScreen(currentUser: user),
                      ),
                    ).then((value) {
                      if (value == true) {
                        _loadAnnouncements();
                      }
                    });
                  },
                  backgroundColor: Colors.purple,
                  child: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Tambah Pengumuman',
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
                bottomNavigationBar: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Profil',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.person, color: Colors.purple),
                        onPressed: () => _showProfileDialog(authService, UserRole.admin),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (user.role == UserRole.teacher) {
              return TeacherHomeScreen(user: user);
            }

            if (user.role == UserRole.student) {
              return StudentHomeScreen(user: user);
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String date,
    required String author,
    required String content,
    required String type,
    required List<String> targetAudience,
    required VoidCallback onTap,
  }) {
    Color typeColor;
    switch (type.toLowerCase()) {
      case 'urgent':
        typeColor = Colors.red;
        break;
      case 'important':
        typeColor = Colors.orange;
        break;
      case 'event':
        typeColor = Colors.green;
        break;
      case 'academic':
      default:
        typeColor = Colors.blue;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                author,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: targetAudience.map((audience) {
                  return Chip(
                    label: Text(
                      audience == 'all'
                          ? 'Semua'
                          : audience == 'teacher'
                              ? 'Guru'
                              : audience == 'student'
                                  ? 'Siswa'
                                  : audience.replaceFirst('class-', 'Kelas '),
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Baca Selengkapnya',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }
}