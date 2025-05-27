import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges().asyncMap(_userFromFirebase);

  Future<User?> get currentUser async {
    if (_firebaseAuth.currentUser == null) return null;
    return await _userFromFirebase(_firebaseAuth.currentUser);
  }

  Future<User?> _userFromFirebase(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) return null;
    
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

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Failed to sign out: $e');
      rethrow;
    }
  }
}

class MockAuthService {
  User? _currentUser;
  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  MockAuthService() {
    debugPrint('Initializing MockAuthService');
    // Initialize with an admin user for testing
    _currentUser = User(
      id: "admin1",
      name: "Admin Sekolah",
      email: "admin@school.edu",
      role: UserRole.admin,
    );
    _authStateController.add(_currentUser);
    debugPrint('Initialized with admin user: ${_currentUser!.name}');

    // Check for persisted user (optional, for testing login persistence)
    _checkPersistedUser().then((_) {
      debugPrint('Persistence check completed, current user: ${_currentUser != null ? _currentUser!.name : 'null'}');
    }).catchError((error) {
      debugPrint('Error during persistence check: $error');
    });
  }

  Future<void> _checkPersistedUser() async {
    try {
      debugPrint('Checking for persisted user');
      await Future.delayed(const Duration(milliseconds: 300));
      final prefs = await SharedPreferences.getInstance();
      final userRole = prefs.getString('user_role');
      final userName = prefs.getString('user_name');
      final userId = prefs.getString('user_id');
      
      debugPrint('Persisted data - userId: ${userId ?? 'null'}, '
          'userName: ${userName ?? 'null'}, '
          'userRole: ${userRole ?? 'null'}');
      
      if (userId != null && userName != null && userRole != null) {
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
        _authStateController.add(_currentUser);
      }
    } catch (e) {
      debugPrint('Error checking persisted user: $e');
      _authStateController.add(_currentUser); // Emit current user again to ensure stream updates
    }
  }

  Future<User?> get currentUser async {
    if (_currentUser != null) {
      debugPrint('Returning current user: ${_currentUser!.name}');
      return _currentUser;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        debugPrint('Reconstructing user from SharedPreferences');
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
          
          _authStateController.add(_currentUser);
        }
      }
    } catch (e) {
      debugPrint('Error in currentUser getter: $e');
    }
    
    return _currentUser;
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
        name: "Admin Sekolah",
        email: email,
        role: UserRole.admin,
      );
    } else {
      throw Exception("Invalid credentials");
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', _currentUser!.role.toString());
    await prefs.setString('user_name', _currentUser!.name);
    await prefs.setString('user_id', _currentUser!.id);
    
    debugPrint('User signed in: ${_currentUser!.name}');
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