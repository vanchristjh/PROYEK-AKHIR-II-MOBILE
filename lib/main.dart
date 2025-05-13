import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'widgets/loading_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize shared preferences
  await SharedPreferences.getInstance();
  
  // Add a try-catch block to handle initialization errors
  try {
    // For Firebase apps, you would initialize Firebase here
    // Even though we're using mock services, we'll set up proper initialization 
    // to fix the loading screen issue
    
    // In a real app with Firebase, we would do:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Instead, we'll just add a small delay to simulate initialization
    debugPrint('Initializing app services...');
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('App initialization completed successfully');
  } catch (e) {
    debugPrint('Error initializing app: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {    // Create a single instance of MockAuthService to be shared across the app
    final authService = MockAuthService();
    
    return MultiProvider(
      providers: [
        Provider<MockAuthService>(
          create: (_) => authService,
          dispose: (_, service) => service.dispose(),
        ),
      ],      child: MaterialApp(
        title: 'SMAN 1 Application',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0D47A1),
            primary: const Color(0xFF0D47A1),
            secondary: const Color(0xFF1E88E5),
            tertiary: const Color(0xFF42A5F5),
            background: Colors.grey[50],
          ),
          useMaterial3: true,          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: AppBarTheme(
            elevation: 0,
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            centerTitle: true,
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
              ),              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
        },
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) {            // Add a timeout to prevent getting stuck on StreamBuilder initialization
            final BuildContext contextCopy = context;
            Future.delayed(const Duration(seconds: 5), () {
              // Using a copied context to avoid the BuildContext across async gap warning
              try {
                // Check if we're still on the initial loading screen after 5 seconds
                if (ModalRoute.of(contextCopy)?.settings.name == null) {
                  // If so, navigate to login as a fallback
                  Navigator.pushReplacement(
                    contextCopy, 
                    MaterialPageRoute(builder: (_) => const LoginScreen())
                  );
                }
              } catch (e) {
                debugPrint('Error during timeout navigation: $e');
              }
            });
            
            return StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                // Handle different connection states
                if (snapshot.connectionState == ConnectionState.active || 
                    snapshot.connectionState == ConnectionState.done) {
                  final user = snapshot.data;
                  if (user == null) {
                    // Not logged in, show login screen
                    return const LoginScreen();
                  } else {
                    // Logged in, show home screen
                    return const HomeScreen();
                  }
                }
                  // Connection state is waiting, show loading with timeout
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
                              'Silahkan coba lagi',
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
                                  MaterialPageRoute(builder: (_) => const LoginScreen())
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
                              ),                            ),
                        ],
                      ),
                    ),
                  ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
