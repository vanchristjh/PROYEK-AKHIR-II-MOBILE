import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/loading_indicator.dart';
import 'student/student_home_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'admin/admin_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  bool _isLoading = true;
  
  // Access auth service through the provider  
  MockAuthService get _authService => Provider.of<MockAuthService>(context, listen: false);
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }  Future<void> _loadUser() async {
    try {
      // Add a timeout to prevent infinite loading
      final user = await _authService.currentUser.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Timed out waiting for current user, navigating to login');
          // If we time out, just return null to go to login screen
          return null;
        },
      );
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        
        // If user is null after timeout, go to login
        if (user == null) {
          debugPrint('User is null, navigating to login screen');
          // Navigate immediately to avoid getting stuck
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // When there's an error, we should also navigate to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
        });
          // We already navigate in the setState above, so no need to do it again here
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: LoadingIndicator(
            timeout: const Duration(seconds: 30),
            timeoutWidget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading timed out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Add your refresh logic here
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_currentUser == null) {
      // User should never be null here due to StreamBuilder in main.dart,
      // but just in case, show a loading state
      return const Scaffold(body: Center(child: Text('Loading user data...')));
    }

    // Based on user role, show the appropriate home screen
    switch (_currentUser!.role) {
      case UserRole.student:
        return StudentHomeScreen(user: _currentUser!);
      case UserRole.teacher:
        return TeacherHomeScreen(user: _currentUser!);
      case UserRole.admin:
        return AdminHomeScreen(user: _currentUser!);
    }
  }
}
