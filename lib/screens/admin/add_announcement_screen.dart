import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sma_girsip/models/user.dart';
import 'package:sma_girsip/models/announcement.dart';
import 'package:sma_girsip/services/announcement_service.dart';

class AddAnnouncementScreen extends StatefulWidget {
  final User currentUser;

  const AddAnnouncementScreen({super.key, required this.currentUser});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _type = 'academic';
  DateTime? _expiryDate;
  final List<String> _targetAudience = [];
  bool _isLoading = false;

  final List<String> _announcementTypes = ['academic', 'event', 'important', 'urgent'];
  final List<String> _classes = ['class-10A', 'class-10B', 'class-11A', 'class-11B', 'class-12A', 'class-12B'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _expiryDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final announcementService = MockAnnouncementService();
      final announcement = Announcement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        content: _contentController.text,
        type: _type,
        targetAudience: _targetAudience.isEmpty ? ['all'] : _targetAudience,
        authorId: widget.currentUser.id,
        authorName: widget.currentUser.name,
        publishDate: DateTime.now(),
        expiryDate: _expiryDate,
      );

      final success = await announcementService.addAnnouncement(announcement);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berhasil ditambahkan')),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan pengumuman')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan pengumuman: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Tambah Pengumuman',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Judul',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Masukkan judul pengumuman',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Isi Pengumuman',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Masukkan isi pengumuman',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Isi pengumuman tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Tipe Pengumuman',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: _announcementTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.replaceFirst(type[0], type[0].toUpperCase())),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _type = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Tanggal Kadaluarsa (Opsional)',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectExpiryDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _expiryDate == null
                              ? 'Pilih tanggal dan waktu'
                              : DateFormat('dd MMMM yyyy, HH:mm').format(_expiryDate!),
                          style: GoogleFonts.poppins(
                            color: _expiryDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Target Audiens',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: _targetAudience.contains('all'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _targetAudience.clear();
                            _targetAudience.add('all');
                          } else {
                            _targetAudience.remove('all');
                          }
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Guru'),
                      selected: _targetAudience.contains('teacher'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _targetAudience.remove('all');
                            _targetAudience.add('teacher');
                          } else {
                            _targetAudience.remove('teacher');
                          }
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Siswa'),
                      selected: _targetAudience.contains('student'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _targetAudience.remove('all');
                            _targetAudience.add('student');
                          } else {
                            _targetAudience.remove('student');
                          }
                        });
                      },
                    ),
                    ..._classes.map((classId) {
                      return ChoiceChip(
                        label: Text(classId.replaceFirst('class-', 'Kelas ')),
                        selected: _targetAudience.contains(classId),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _targetAudience.remove('all');
                              _targetAudience.add(classId);
                            } else {
                              _targetAudience.remove(classId);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitAnnouncement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Tambah Pengumuman'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}