import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/user_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});
  
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _classIdController = TextEditingController();
  
  UserRole _selectedRole = UserRole.student;
  List<String> _selectedSubjects = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  final List<String> _availableSubjects = [
    'math',
    'science',
    'history',
    'geography',
    'english',
    'art',
    'music',
    'physical_education',
    'biology',
    'chemistry',
    'physics',
    'computer_science',
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _classIdController.dispose();
    super.dispose();
  }
  
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Additional validation for teachers
    if (_selectedRole == UserRole.teacher && _selectedSubjects.isEmpty) {
      setState(() {
        _errorMessage = 'Please select at least one subject';
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Create user object
      final newUser = User(
        id: '', // Will be set by the service
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        classId: _selectedRole == UserRole.student ? _classIdController.text.trim() : null,
        subjectIds: _selectedRole == UserRole.teacher ? _selectedSubjects : null,
      );
      
      // Get user service
      final userService = MockUserService();
      
      // Create user
      final userId = await userService.createUser(newUser);
      
      if (userId != null && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create user. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New User'),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Creating user...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_add,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Create New User Account',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Fill in the details below to create a new user',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Basic info card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section title
                            Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            // Role selection
                            const Text(
                              'Select User Role',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRoleSelector(),
                            const SizedBox(height: 20),
                            
                            // Name field
                            _buildTextField(
                              controller: _nameController,
                              labelText: 'Full Name',
                              prefixIcon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Email field
                            _buildTextField(
                              controller: _emailController,
                              labelText: 'Email Address',
                              prefixIcon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Role-specific fields
                    if (_selectedRole == UserRole.student)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              const Row(
                                children: [
                                  Icon(Icons.school, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Student Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 16),
                              
                              // Class ID field
                              _buildTextField(
                                controller: _classIdController,
                                labelText: 'Class ID',
                                hintText: 'e.g., class-10a',
                                prefixIcon: Icons.class_,
                                validator: (value) {
                                  if (_selectedRole == UserRole.student && 
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Please enter a class ID';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_selectedRole == UserRole.teacher)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section title
                              const Row(
                                children: [
                                  Icon(Icons.cast_for_education, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Teaching Subjects',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              
                              const Text(
                                'Select the subjects this teacher will teach:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Subject selection
                              Wrap(
                                spacing: 8,
                                runSpacing: 12,
                                children: _availableSubjects.map((subject) {
                                  final isSelected = _selectedSubjects.contains(subject);
                                  
                                  return FilterChip(
                                    label: Text(_formatSubjectName(subject)),
                                    selected: isSelected,
                                    showCheckmark: true,
                                    checkmarkColor: Colors.white,
                                    selectedColor: Colors.green,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.grey.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedSubjects.add(subject);
                                        } else {
                                          _selectedSubjects.remove(subject);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              
                              if (_selectedRole == UserRole.teacher && _selectedSubjects.isEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.amber[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Please select at least one subject',
                                          style: TextStyle(color: Colors.amber[800], fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Create User',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: UserRole.values.map((role) {
          String label;
          IconData icon;
          Color color;
          
          switch (role) {
            case UserRole.student:
              label = 'Student';
              icon = Icons.school;
              color = Colors.blue;
              break;
            case UserRole.teacher:
              label = 'Teacher';
              icon = Icons.cast_for_education;
              color = Colors.green;
              break;
            case UserRole.admin:
              label = 'Admin';
              icon = Icons.admin_panel_settings;
              color = Colors.purple;
              break;
          }
          
          final isSelected = _selectedRole == role;
          
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedRole = role;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected 
                    ? Border.all(color: color, width: 2) 
                    : Border.all(color: Colors.transparent),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? color : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
  
  String _formatSubjectName(String subject) {
    // Convert snake_case to Title Case
    return subject.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
