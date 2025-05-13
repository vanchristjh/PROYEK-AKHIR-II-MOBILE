import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';
import 'package:intl/intl.dart';

class AddAnnouncementScreen extends StatefulWidget {
  final User currentUser;
  
  const AddAnnouncementScreen({
    super.key, 
    required this.currentUser,
  });
  
  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime? _expiryDate;
  List<String> _targetAudience = ['all'];
  bool _isLoading = false;
  String? _errorMessage;
  
  final List<String> _audienceOptions = ['all', 'teacher', 'student'];
  final List<String> _classOptions = [
    'class-10a', 
    'class-10b',
    'class-11a',
    'class-11b',
    'class-12a',
    'class-12b',
  ];
  
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy');
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Create announcement object
      final announcement = Announcement(
        id: 'announcement_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        publishDate: DateTime.now(),
        authorId: widget.currentUser.id,
        authorName: widget.currentUser.name,
        targetAudience: _targetAudience,
        expiryDate: _expiryDate,
      );
      
      // Get announcement service
      final announcementService = MockAnnouncementService();
      // Create announcement
      final bool success = await announcementService.createAnnouncement(announcement);
      
      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create announcement. Please try again.';
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
  
  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && mounted) {
      setState(() {
        _expiryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23, // Hour set to end of day
          59, // Minutes
          59, // Seconds
        );
      });
    }
  }
  
  void _toggleAudienceSelection(String audience) {
    setState(() {
      // If selecting "all", clear other selections
      if (audience == 'all') {
        _targetAudience = ['all'];
        return;
      }
      
      // If "all" is already selected, remove it when selecting others
      if (_targetAudience.contains('all')) {
        _targetAudience.remove('all');
      }
      
      // Toggle selection
      if (_targetAudience.contains(audience)) {
        _targetAudience.remove(audience);
        
        // If no audience is selected, default to "all"
        if (_targetAudience.isEmpty) {
          _targetAudience = ['all'];
        }
      } else {
        _targetAudience.add(audience);
      }
    });
  }
  
  void _toggleClassSelection(String classId, bool selected) {
    setState(() {
      // If "all" is selected, remove it when selecting specific class
      if (_targetAudience.contains('all')) {
        _targetAudience.remove('all');
        // Make sure we keep 'student' role when removing 'all'
        if (!_targetAudience.contains('student')) {
          _targetAudience.add('student');
        }
      }
      
      if (selected) {
        _targetAudience.add(classId);
      } else {
        _targetAudience.remove(classId);
        
        // If no class and no specific audience is selected, default to "all"
        if (_targetAudience.isEmpty) {
          _targetAudience = ['all'];
        }
      }
    });
  }
  
  Widget _buildAudienceChip(String label, String value, IconData icon, Color color) {
    final bool isSelected = _targetAudience.contains(value);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: color,
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) => _toggleAudienceSelection(value),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Announcement'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Publishing announcement...',
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
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.campaign,
                          size: 40,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Create New Announcement',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'This will be visible to the selected audience',
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
                    
                    // Author info card
                    Card(
                      elevation: 1,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Icon(
                                Icons.person,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Author',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    widget.currentUser.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Announcement content card
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
                            Row(
                              children: [
                                Icon(Icons.text_fields, color: Colors.blue.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Announcement Content',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            // Title field
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Announcement Title',
                                prefixIcon: const Icon(Icons.title),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                hintText: 'Enter a clear, concise title',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Content field
                            TextFormField(
                              controller: _contentController,
                              decoration: InputDecoration(
                                labelText: 'Announcement Content',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                hintText: 'Enter the details of your announcement here...',
                              ),
                              maxLines: 10,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter content';
                                }
                                if (value.trim().length < 10) {
                                  return 'Content is too short';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Target audience card
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
                            Row(
                              children: [
                                Icon(Icons.people, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Target Audience',
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
                              'Who should see this announcement?',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 12,
                              children: [
                                _buildAudienceChip(
                                  'Everyone', 
                                  'all',
                                  Icons.public,
                                  Colors.purple,
                                ),
                                _buildAudienceChip(
                                  'Teachers', 
                                  'teacher',
                                  Icons.cast_for_education,
                                  Colors.green,
                                ),
                                _buildAudienceChip(
                                  'Students', 
                                  'student',
                                  Icons.school,
                                  Colors.blue,
                                ),
                              ],
                            ),
                            
                            // Show class options only if "student" is selected
                            if (_targetAudience.contains('student') && !_targetAudience.contains('all')) ...[
                              const SizedBox(height: 20),
                              const Text(
                                'Specific Classes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Optional, select to target specific classes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                childAspectRatio: 2.5,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                children: _classOptions.map((classId) {
                                  final isSelected = _targetAudience.contains(classId);
                                  final className = classId.replaceFirst('class-', 'Class ');
                                  
                                  return Material(
                                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      onTap: () => _toggleClassSelection(
                                        classId,
                                        !isSelected,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.blue.shade400
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            isSelected
                                                ? Icon(
                                                    Icons.check_circle,
                                                    size: 18,
                                                    color: Colors.blue.shade700,
                                                  )
                                                : Icon(
                                                    Icons.class_,
                                                    size: 18,
                                                    color: Colors.grey.shade600,
                                                  ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                className,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.blue.shade700
                                                      : Colors.grey.shade800,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Expiry date card
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
                            Row(
                              children: [
                                Icon(Icons.event_busy, color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                const Text(
                                  'Expiry Date',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            
                            Text(
                              'Set a date when this announcement will no longer be shown.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _expiryDate == null
                                ? ElevatedButton.icon(
                                    onPressed: _selectExpiryDate,
                                    icon: const Icon(Icons.calendar_today),
                                    label: const Text('Set Expiry Date'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.orange.shade800,
                                      backgroundColor: Colors.orange.shade50,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.orange.shade50,
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.event,
                                          color: Colors.orange.shade800,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Expires on:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _dateFormat.format(_expiryDate!),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.orange.shade800,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.orange.shade800,
                                          onPressed: _selectExpiryDate,
                                          tooltip: 'Change Date',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.clear),
                                          color: Colors.red,
                                          onPressed: () {
                                            setState(() {
                                              _expiryDate = null;
                                            });
                                          },
                                          tooltip: 'Clear Date',
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Publish button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveAnnouncement,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'Publish Announcement',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
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
}
