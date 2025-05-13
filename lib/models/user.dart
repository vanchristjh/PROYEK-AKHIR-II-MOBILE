class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? classId; // For students
  final List<String>? subjectIds; // For teachers

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.subjectIds,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${map['role']}',
      ),
      classId: map['classId'],
      subjectIds: map['subjectIds'] != null
          ? List<String>.from(map['subjectIds'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'classId': classId,
      'subjectIds': subjectIds,
    };
  }
}

enum UserRole {
  student,
  teacher,
  admin,
}
