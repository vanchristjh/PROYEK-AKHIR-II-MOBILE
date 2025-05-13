import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges().asyncMap(_userFromFirebase);

  // Current user getter
  Future<User?> get currentUser async {
    if (_firebaseAuth.currentUser == null) return null;
    return await _userFromFirebase(_firebaseAuth.currentUser);
  }

  // Convert Firebase User to our custom User model
  Future<User?> _userFromFirebase(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) return null;
    
    // Get user data from Firestore
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return User.fromMap({
          'id': firebaseUser.uid,
          ...userDoc.data() as Map<String, dynamic>,
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      return await _userFromFirebase(userCredential.user);
    } catch (e) {
      debugPrint('Failed to sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear any saved user data
    } catch (e) {
      debugPrint('Failed to sign out: $e');
      rethrow;
    }
  }
}

// Mock implementation for testing/development without Firebase setup
class MockAuthService {
  User? _currentUser;

  // Provide a stream that mimics auth state changes
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;
  MockAuthService() {
    debugPrint('Initializing MockAuthService');
    // Start with no user
    _authStateController.add(null);
    
    // Check if user is already logged in from shared preferences
    _checkPersistedUser().then((_) {
      debugPrint('Persistence check completed, current user: ${_currentUser != null ? 'exists' : 'null'}');
    }).catchError((error) {
      debugPrint('Error during persistence check: $error');
    });
  }
  Future<void> _checkPersistedUser() async {
    try {
      debugPrint('Checking for persisted user');
      
      // Add a small artificial delay to simulate real-world latency
      // but prevent it from being too long
      await Future.delayed(const Duration(milliseconds: 300));
      
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      final userName = prefs.getString('user_name');
      final userId = prefs.getString('user_id');
      
      debugPrint('Persisted data - userId: ${userId != null ? 'exists' : 'null'}, '
          'userName: ${userName != null ? 'exists' : 'null'}, '
          'userRole: ${userRole != null ? userRole : 'null'}');
      
      if (userId != null && userName != null && userRole != null) {
        // Recreate the user from stored data
        final role = userRole.contains('student') 
            ? UserRole.student 
            : userRole.contains('teacher') 
                ? UserRole.teacher 
                : UserRole.admin;
        
        _currentUser = User(
          id: userId,
          name: userName,
          email: role == UserRole.student 
              ? "student@school.edu" 
              : role == UserRole.teacher 
                  ? "teacher@school.edu" 
                  : "admin@school.edu",
          role: role,
          classId: role == UserRole.student ? "class-10a" : null,
          subjectIds: role == UserRole.teacher ? ["math", "science"] : null,
        );
        
        debugPrint('User recreated from persistence: ${_currentUser!.name} (${_currentUser!.role})');
        
        // Emit the user to the stream
        _authStateController.add(_currentUser);
      } else {
        debugPrint('No persisted user found');
        // Make sure we explicitly emit null to confirm initialization completed
        _authStateController.add(null);
      }
    } catch (e) {
      debugPrint('Error checking persisted user: $e');
      // Always emit something to indicate initialization is complete
      _authStateController.add(null);
    }
  }
  Future<User?> get currentUser async {
    // First check if we already have a current user
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Otherwise, check shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      // If we have a user ID stored but no current user, it means 
      // _checkPersistedUser hasn't completed yet, so we need to wait
      if (userId != null) {
        // Create a timeout to prevent waiting indefinitely
        bool userLoaded = false;
        
        // Try to wait for a brief time for the persisted user check to complete
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (_currentUser != null) {
            userLoaded = true;
            break;
          }
        }
        
        // If waiting didn't help, reconstruct the user from SharedPreferences
        if (!userLoaded) {
          debugPrint('Reconstructing user from SharedPreferences as _checkPersistedUser seems delayed');
          final userRole = prefs.getString('user_role');
          final userName = prefs.getString('user_name');
          
          if (userName != null && userRole != null) {
            final role = userRole.contains('student') 
                ? UserRole.student 
                : userRole.contains('teacher') 
                    ? UserRole.teacher 
                    : UserRole.admin;
            
            _currentUser = User(
              id: userId,
              name: userName,
              email: role == UserRole.student 
                  ? "student@school.edu" 
                  : role == UserRole.teacher 
                      ? "teacher@school.edu" 
                      : "admin@school.edu",
              role: role,
              classId: role == UserRole.student ? "class-10a" : null,
              subjectIds: role == UserRole.teacher ? ["math", "science"] : null,
            );
            
            // Emit the user to the stream
            _authStateController.add(_currentUser);
          }
        }
        
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error in currentUser getter: $e');
    }
    
    return null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    if (email == "teacher@school.edu" && password == "password") {
      _currentUser = User(
        id: "teacher1",
        name: "Guru Demo",
        email: email,
        role: UserRole.teacher,
        subjectIds: ["math", "science"],
      );
    } else if (email == "student@school.edu" && password == "password") {
      _currentUser = User(
        id: "student1",
        name: "Murid Demo",
        email: email,
        role: UserRole.student,
        classId: "class-10a",
      );
    } else if (email == "admin@school.edu" && password == "password") {
      _currentUser = User(
        id: "admin1",
        name: "Admin Demo",
        email: email,
        role: UserRole.admin,
      );
    } else {
      throw Exception("Invalid credentials");
    }
    
    // Save to shared prefs for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', _currentUser!.role.toString());
    await prefs.setString('user_name', _currentUser!.name);
    await prefs.setString('user_id', _currentUser!.id);
    
    _authStateController.add(_currentUser);
    return _currentUser;
  }
  Future<void> signOut() async {
    debugPrint('Signing out user');
    _currentUser = null;
    _authStateController.add(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('User signed out successfully, preferences cleared');
  }
  
  void dispose() {
    debugPrint('Disposing MockAuthService');
    try {
      if (!_authStateController.isClosed) {
        _authStateController.close();
        debugPrint('Auth state controller closed successfully');
      }
    } catch (e) {
      debugPrint('Error while disposing MockAuthService: $e');
    }
  }
}
