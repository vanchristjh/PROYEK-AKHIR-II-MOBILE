import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/user_service.dart';

class EditUserScreen extends StatefulWidget {
  final User user;
  
  const EditUserScreen({super.key, required this.user});
  
  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _classIdController;
  
  UserRole? _selectedRole;
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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _classIdController = TextEditingController(text: widget.user.classId ?? '');
    _selectedRole = widget.user.role;
    _selectedSubjects = widget.user.subjectIds?.toList() ?? [];
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _classIdController.dispose();
    super.dispose();
  }
  
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Create updated user object
      final updatedUser = User(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole!,
        classId: _selectedRole == UserRole.student ? _classIdController.text.trim() : null,
        subjectIds: _selectedRole == UserRole.teacher ? _selectedSubjects : null,
      );
      
      // Get user service
      final userService = MockUserService();
      
      // Update user
      final success = await userService.updateUser(updatedUser);
      
      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update user. Please try again.';
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
        title: const Text('Edit User Profile'),
        elevation: 0,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: _saveUser,
                ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Saving user...',
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
                    // Header with user info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.person,
                            color: primaryColor,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editing User',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                widget.user.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
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
                    
                    const SizedBox(height: 24),
                    
                    // Form sections
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Role selection
                            const Text(
                              'User Role',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRoleSelector(),
                            const SizedBox(height: 24),
                            
                            // Basic information
                            const Text(
                              'Basic Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameController, 
                              label: 'Full Name', 
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController, 
                              label: 'Email Address', 
                              icon: Icons.email,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Student Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _classIdController,
                                label: 'Class ID',
                                icon: Icons.school,
                                helperText: 'Example: class-10a',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Teacher Subjects',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Select the subjects this teacher can teach:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableSubjects.map((subject) {
                                  final isSelected = _selectedSubjects.contains(subject);
                                  
                                  return FilterChip(
                                    label: Text(_formatSubjectName(subject)),
                                    selected: isSelected,
                                    showCheckmark: true,
                                    checkmarkColor: Colors.white,
                                    selectedColor: primaryColor,
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Please select at least one subject',
                                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading 
          ? null
          : BottomAppBar(
              color: Colors.white,
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<UserRole>(
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          value: _selectedRole,
          icon: const Icon(Icons.arrow_drop_down),
          items: UserRole.values.map((role) {
            String label;
            IconData icon;
            
            switch (role) {
              case UserRole.student:
                label = 'Student';
                icon = Icons.school;
                break;
              case UserRole.teacher:
                label = 'Teacher';
                icon = Icons.cast_for_education;
                break;
              case UserRole.admin:
                label = 'Administrator';
                icon = Icons.admin_panel_settings;
                break;
            }
            
            return DropdownMenuItem(
              value: role,
              child: Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a role';
            }
            return null;
          },
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
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
