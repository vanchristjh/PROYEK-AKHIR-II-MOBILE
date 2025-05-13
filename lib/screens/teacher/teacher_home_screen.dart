import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'tabs/teacher_attendance_tab.dart';
import 'tabs/teacher_announcements_tab.dart';
import 'tabs/teacher_schedule_tab.dart';
import 'tabs/teacher_profile_tab.dart';

class TeacherHomeScreen extends StatefulWidget {
  final User user;
  
  const TeacherHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  
  // Use provider to access the auth service  
  MockAuthService get _authService => Provider.of<MockAuthService>(context, listen: false);
  
  late final List<Widget> _tabs;
  
  @override
  void initState() {
    super.initState();
    _tabs = [
      TeacherAnnouncementsTab(user: widget.user),
      TeacherAttendanceTab(user: widget.user),
      TeacherScheduleTab(user: widget.user),
      TeacherProfileTab(user: widget.user, onLogout: _handleLogout),
    ];
  }
  
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[800],
            ),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }
  
  String _getScreenTitle() {
    switch (_currentIndex) {
      case 0: return 'Informasi dan Pengumuman';
      case 1: return 'Manajemen Absensi';
      case 2: return 'Jadwal Mengajar';
      case 3: return 'Profil Guru';
      default: return 'SMAN 1 Teacher App';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _getScreenTitle(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.teal.shade500,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
              ],
            ),
          ),
          child: _tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 11,
            ),
            elevation: 20,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.announcement_outlined),
                activeIcon: Icon(Icons.announcement),
                label: 'Pengumuman',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.how_to_reg_outlined),
                activeIcon: Icon(Icons.how_to_reg),
                label: 'Absensi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule_outlined),
                activeIcon: Icon(Icons.schedule),
                label: 'Jadwal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 3 ? null : FloatingActionButton(
        onPressed: () {
          // Action based on current tab
          switch (_currentIndex) {
            case 0: // Announcements tab
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buat pengumuman baru')),
              );
              break;
            case 1: // Attendance tab
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rekam absensi baru')),
              );
              break;
            case 2: // Schedule tab
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lihat detail jadwal')),
              );
              break;
          }
        },
        backgroundColor: _currentIndex == 0 
            ? Colors.green.shade700 
            : _currentIndex == 1 
                ? Colors.teal.shade600
                : Colors.blue.shade700,
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Icon(
          _currentIndex == 0 
              ? Icons.add_comment
              : _currentIndex == 1 
                  ? Icons.edit_calendar
                  : Icons.calendar_month,
          color: Colors.white,
        ),
      ),
    );
  }
}
