import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../models/announcement.dart';
import '../../../services/announcement_service.dart';
import '../../../widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import '../edit_announcement_screen.dart';
import '../add_announcement_screen.dart';
import '../../announcement_detail_screen.dart';

class AdminAnnouncementsTab extends StatefulWidget {
  final User adminUser;
  
  const AdminAnnouncementsTab({
    super.key,
    required this.adminUser,
  });

  @override
  State<AdminAnnouncementsTab> createState() => _AdminAnnouncementsTabState();
}

class _AdminAnnouncementsTabState extends State<AdminAnnouncementsTab> {
  bool _isLoading = true;
  List<Announcement> _announcements = [];
  String? _errorMessage;
  
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _timeFormat = DateFormat('HH:mm');
  
  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final announcementService = MockAnnouncementService();
      final announcements = await announcementService.getUserAnnouncements(
        widget.adminUser.id,
        'admin',
        null
      );
      
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load announcements: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete the announcement "${announcement.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() => _isLoading = true);
    
    try {
      final announcementService = MockAnnouncementService();
      final success = await announcementService.deleteAnnouncement(announcement.id);
      
      if (success && mounted) {
        await _loadAnnouncements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete announcement';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete announcement: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _editAnnouncement(Announcement announcement) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAnnouncementScreen(
          announcement: announcement,
          currentUser: widget.adminUser,
        ),
      ),
    );
    
    if (result == true) {
      await _loadAnnouncements();
    }
  }
  
  Future<void> _addAnnouncement() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAnnouncementScreen(currentUser: widget.adminUser),
      ),
    );
    
    if (result == true) {
      await _loadAnnouncements();
    }
  }

  String _getTargetAudienceLabel(List<String> targetAudience) {
    if (targetAudience.contains('all')) {
      return 'Everyone';
    } else {
      final labels = <String>[];
      if (targetAudience.contains('student')) labels.add('Students');
      if (targetAudience.contains('teacher')) labels.add('Teachers');
      
      final classTargets = targetAudience.where(
        (target) => target.startsWith('class-') || target.startsWith('class_')
      ).toList();
      
      if (classTargets.isNotEmpty) {
        if (classTargets.length == 1) {
          labels.add(classTargets.first.replaceFirst('class-', 'Class '));
        } else {
          labels.add('${classTargets.length} Classes');
        }
      }
      
      return labels.join(', ');
    }
  }
  
  List<Announcement> get _activeAnnouncements {
    final now = DateTime.now();
    return _announcements.where((a) => 
      a.expiryDate == null || a.expiryDate!.isAfter(now)
    ).toList();
  }
  
  List<Announcement> get _expiredAnnouncements {
    final now = DateTime.now();
    return _announcements.where((a) => 
      a.expiryDate != null && a.expiryDate!.isBefore(now)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorView();
    }
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mark_email_unread),
                      const SizedBox(width: 8),
                      const Text('Active'),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _activeAnnouncements.length.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 8),
                      const Text('Expired'),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _expiredAnnouncements.length.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              labelColor: Colors.blue.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade700,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnnouncementsView(_activeAnnouncements, isActive: true),
            _buildAnnouncementsView(_expiredAnnouncements, isActive: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addAnnouncement,
          tooltip: 'Add Announcement',
          icon: const Icon(Icons.add),
          label: const Text('New Announcement'),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
  
  Widget _buildAnnouncementsView(List<Announcement> announcements, {required bool isActive}) {
    if (announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.campaign_outlined : Icons.history,
                size: 64,
                color: isActive ? Colors.blue.shade300 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isActive 
                ? 'No Active Announcements' 
                : 'No Expired Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isActive 
                ? 'Create your first announcement' 
                : 'Expired announcements will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (isActive)
              ElevatedButton.icon(
                onPressed: _addAnnouncement,
                icon: const Icon(Icons.add),
                label: const Text('Create Announcement'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _buildAnnouncementCard(
            announcement, 
            isActive: isActive,
          );
        },
      ),
    );
  }
  
  Widget _buildAnnouncementCard(Announcement announcement, {required bool isActive}) {
    final bool isExpired = announcement.expiryDate != null && 
      announcement.expiryDate!.isBefore(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpired ? Colors.grey.shade200 : Colors.blue.shade100,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailScreen(
                announcement: announcement,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isExpired ? Colors.grey.shade50 : Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.campaign,
                    size: 20,
                    color: isExpired ? Colors.grey.shade600 : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.grey.shade700 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expired',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isExpired ? Colors.grey.shade500 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dateFormat.format(announcement.publishDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.grey.shade600 : Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isExpired ? Colors.grey.shade500 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeFormat.format(announcement.publishDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.grey.shade600 : Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    announcement.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isExpired ? Colors.grey.shade600 : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? Colors.grey.shade100 
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpired 
                                ? Colors.grey.shade300 
                                : Colors.amber.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 12,
                              color: isExpired 
                                  ? Colors.grey.shade600 
                                  : Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getTargetAudienceLabel(announcement.targetAudience),
                              style: TextStyle(
                                fontSize: 12,
                                color: isExpired 
                                    ? Colors.grey.shade600 
                                    : Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired 
                              ? Colors.grey.shade100 
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpired 
                                ? Colors.grey.shade300 
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: isExpired 
                                  ? Colors.grey.shade600 
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              announcement.authorName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isExpired 
                                    ? Colors.grey.shade600 
                                    : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      if (announcement.expiryDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isExpired 
                                ? Colors.grey.shade100 
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isExpired 
                                  ? Colors.grey.shade300 
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpired ? Icons.event_busy : Icons.event_available,
                                size: 12,
                                color: isExpired 
                                    ? Colors.grey.shade600 
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isExpired 
                                    ? 'Expired' 
                                    : 'Expires ${_dateFormat.format(announcement.expiryDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired 
                                      ? Colors.grey.shade600 
                                      : Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            Divider(
              height: 1,
              color: isExpired ? Colors.grey.shade200 : Colors.blue.shade100,
            ),
            
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetailScreen(
                            announcement: announcement,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.visibility,
                      size: 18,
                      color: isExpired ? Colors.grey.shade600 : Colors.blue.shade700,
                    ),
                    label: Text(
                      'View',
                      style: TextStyle(
                        color: isExpired ? Colors.grey.shade600 : Colors.blue.shade700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _editAnnouncement(announcement),
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: isExpired ? Colors.grey.shade600 : Colors.amber.shade700,
                    ),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: isExpired ? Colors.grey.shade600 : Colors.amber.shade700,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteAnnouncement(announcement),
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Announcements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: _loadAnnouncements,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
