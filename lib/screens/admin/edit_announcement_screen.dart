import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';
import 'package:intl/intl.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final User currentUser;
  final Announcement announcement;

  const EditAnnouncementScreen({
    super.key,
    required this.currentUser,
    required this.announcement,
  });

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  DateTime? _expiryDate;
  late List<String> _targetAudience;
  bool _isLoading = false;
  String? _errorMessage;

  List<String> _audienceOptions = ['all', 'teacher', 'student'];
  List<String> _classOptions = [
    'class-10a',
    'class-10b',
    'class-11a',
    'class-11b',
    'class-12a',
    'class-12b',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _expiryDate = widget.announcement.expiryDate;
    _targetAudience = List.from(widget.announcement.targetAudience);
  }

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
      final updatedAnnouncement = Announcement(
        id: widget.announcement.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        publishDate: widget.announcement.publishDate,
        authorId: widget.announcement.authorId,
        authorName: widget.announcement.authorName,
        targetAudience: _targetAudience,
        expiryDate: _expiryDate,
      );

      final announcementService = MockAnnouncementService();

      final success = await announcementService.updateAnnouncement(updatedAnnouncement);

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update announcement. Please try again.';
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
          23,
          59,
          59,
        );
      });
    }
  }

  void _toggleAudienceSelection(String audience) {
    setState(() {
      if (audience == 'all') {
        _targetAudience = ['all'];
        return;
      }

      if (_targetAudience.contains('all')) {
        _targetAudience.remove('all');
      }

      if (_targetAudience.contains(audience)) {
        _targetAudience.remove(audience);

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
      if (_targetAudience.contains('all')) {
        _targetAudience.remove('all');
        if (!_targetAudience.contains('student')) {
          _targetAudience.add('student');
        }
      }

      if (selected) {
        _targetAudience.add(classId);
      } else {
        _targetAudience.remove(classId);

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
        title: const Text('Edit Announcement'),
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
                  onPressed: _saveAnnouncement,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Published on: ${widget.announcement.publishDate.day}/${widget.announcement.publishDate.month}/${widget.announcement.publishDate.year}',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Announcement Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Announcement Content',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
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
                    const SizedBox(height: 24),
                    const Text(
                      'Target Audience',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAudienceChip('Everyone', 'all', Icons.people, Colors.blue),
                        _buildAudienceChip('Teachers', 'teacher', Icons.person, Colors.green),
                        _buildAudienceChip('Students', 'student', Icons.school, Colors.orange),
                      ],
                    ),
                    if (_targetAudience.contains('student') && !_targetAudience.contains('all'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'Specific Classes',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Text(
                            'Optional, select to target specific classes',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _classOptions.map((classId) {
                              return FilterChip(
                                label: Text(classId.replaceFirst('class-', 'Class ')),
                                selected: _targetAudience.contains(classId),
                                onSelected: (selected) => _toggleClassSelection(classId, selected),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Expiry Date (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _expiryDate == null
                              ? TextButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: const Text('Set Expiry Date'),
                                  onPressed: _selectExpiryDate,
                                )
                              : Row(
                                  children: [
                                    Text(
                                      '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: _selectExpiryDate,
                                      tooltip: 'Change Date',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
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
                        onPressed: _saveAnnouncement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
}
