import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sma_girsip/screens/login_screen.dart';
import 'package:sma_girsip/screens/home_screen.dart';
import 'package:sma_girsip/screens/admin/admin_home_screen.dart';
import 'package:sma_girsip/screens/teacher/teacher_home_screen.dart';
import 'package:sma_girsip/screens/student/student_home_screen.dart';
import 'package:sma_girsip/screens/admin/admin_user_management_screen.dart';
import 'package:sma_girsip/services/auth_service.dart';
import 'package:sma_girsip/models/user.dart';
import 'package:sma_girsip/widgets/loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  await SharedPreferences.getInstance();

  // Simulate app initialization
  debugPrint('Initializing app services...');
  await Future.delayed(const Duration(milliseconds: 500));
  debugPrint('App initialization completed successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = MockAuthService();

    return MultiProvider(
      providers: [
        Provider<MockAuthService>(
          create: (_) => authService,
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'SMAN 1 Girsip',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            primary: const Color(0xFF0D47A1),
            secondary: const Color(0xFF1E88E5),
            tertiary: const Color(0xFF42A5F5),
            background: Colors.grey[50],
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            centerTitle: false,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 3,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          scaffoldBackgroundColor: Colors.grey[50],
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin_home': (context) => AdminHomeScreen(user: _getDummyUser(UserRole.admin)),
          '/teacher_home': (context) => TeacherHomeScreen(user: _getDummyUser(UserRole.teacher)),
          '/student_home': (context) => StudentHomeScreen(user: _getDummyUser(UserRole.student)),
          '/admin_user_management': (context) => const AdminUserManagementScreen(),
        },
        debugShowCheckedModeBanner: false,
        home: Consumer<MockAuthService>(
          builder: (context, authService, child) {
            return StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                debugPrint('StreamBuilder state: ${snapshot.connectionState}, Data: ${snapshot.data?.name ?? 'null'}');

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1565C0),
                            const Color(0xFF1976D2),
                            const Color(0xFF42A5F5).withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: LoadingIndicator(
                          timeout: const Duration(seconds: 5),
                          timeoutWidget: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 56,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat aplikasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Silakan coba lagi',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  'Coba Lagi',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1565C0),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('StreamBuilder error: ${snapshot.error}');
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 56,
                            color: Colors.red[700],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Terjadi kesalahan',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan coba lagi nanti',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              'Coba Lagi',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final user = snapshot.data;
                if (user == null) {
                  debugPrint('No user found, navigating to LoginScreen');
                  return const LoginScreen();
                } else {
                  debugPrint('User found: ${user.name} (${user.role}), navigating to role-specific screen');
                  switch (user.role) {
                    case UserRole.admin:
                      return AdminHomeScreen(user: user);
                    case UserRole.teacher:
                      return TeacherHomeScreen(user: user);
                    case UserRole.student:
                      return StudentHomeScreen(user: user);
                    default:
                      return const LoginScreen();
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }

  // Helper function untuk dummy user (jika diperlukan oleh routes)
  static User _getDummyUser(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return User(
          id: 'admin1',
          name: 'Admin Sekolah',
          email: 'admin@school.edu',
          role: UserRole.admin,
        );
      case UserRole.teacher:
        return User(
          id: 'teacher1',
          name: 'Guru Demo',
          email: 'teacher@school.edu',
          role: UserRole.teacher,
          subjectIds: ['math', 'science'],
        );
      case UserRole.student:
        return User(
          id: 'student1',
          name: 'Murid Demo',
          email: 'student@school.edu',
          role: UserRole.student,
          classId: 'class-10a',
        );
    }
  }
}