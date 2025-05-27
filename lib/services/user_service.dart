import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all users
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      return snapshot.docs.map((doc) {
        return User.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }
  
  // Get specific user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return User.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching user: $e');
      return null;
    }
  }
  
  // Create new user
  Future<String?> createUser(User user) async {
    try {
      final docRef = await _firestore.collection('users').add(user.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }
  
  // Update user
  Future<bool> updateUser(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }
  
  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }
  
  // Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    try {
      final roleStr = role.toString().split('.').last;
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: roleStr)
          .get();
      
      return snapshot.docs.map((doc) {
        return User.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users by role: $e');
      return [];
    }
  }
  
  // Get students by class
  Future<List<User>> getStudentsByClass(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: classId)
          .get();
      
      return snapshot.docs.map((doc) {
        return User.fromMap({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList();
    } catch (e) {
      debugPrint('Error fetching students by class: $e');
      return [];
    }
  }
}

// Mock implementation for testing/development without Firebase setup
class MockUserService {
  // Mock user data
  final List<User> _users = [
    User(
      id: "admin1",
      name: "Admin Demo",
      email: "admin@school.edu",
      role: UserRole.admin,
    ),
    User(
      id: "teacher1",
      name: "Guru Demo",
      email: "teacher@school.edu",
      role: UserRole.teacher,
      subjectIds: ["math", "science"],
    ),
    User(
      id: "student1",
      name: "Murid Demo",
      email: "student@school.edu",
      role: UserRole.student,
      classId: "class-10a",
    ),
    User(
      id: "teacher2",
      name: "Andi Wijaya",
      email: "andi@school.edu",
      role: UserRole.teacher,
      subjectIds: ["history", "geography"],
    ),
    User(
      id: "student2",
      name: "Budi Santoso",
      email: "budi@school.edu",
      role: UserRole.student,
      classId: "class-11a",
    ),
  ];

  // Get all users
  Future<List<User>> getAllUsers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return List.from(_users);
  }
  
  // Get specific user by ID
  Future<User?> getUserById(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _users.firstWhere((user) => user.id == userId);
  }
  
  // Create new user
  Future<String?> createUser(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate a unique ID
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create a new user with the generated ID
    final newUser = User(
      id: id,
      name: user.name,
      email: user.email,
      role: user.role,
      classId: user.classId,
      subjectIds: user.subjectIds,
    );
    
    // Add to mock data
    _users.add(newUser);
    
    return id;
  }
  
  // Update user
  Future<bool> updateUser(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Delete user
  Future<bool> deleteUser(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    try {
      final prevLength = _users.length;
      _users.removeWhere((user) => user.id == userId);
      return _users.length < prevLength;
    } catch (e) {
      return false;
    }
  }
  
  // Get users by role
  Future<List<User>> getUsersByRole(UserRole role) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _users.where((user) => user.role == role).toList();
  }
  
  // Get students by class
  Future<List<User>> getStudentsByClass(String classId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return _users.where((user) => 
      user.role == UserRole.student && user.classId == classId
    ).toList();
  }
}