import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../models/journal_entry.dart';
import '../../services/journal_service.dart';

class StudentJournalEntries extends StatefulWidget {
  const StudentJournalEntries({super.key});

  @override
  State<StudentJournalEntries> createState() => _StudentJournalEntriesState();
}

class _StudentJournalEntriesState extends State<StudentJournalEntries> {
  List<JournalEntry> _journalEntries = [];
  List<JournalEntry> _filteredEntries = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadJournalEntries();
  }

  Future<void> _loadJournalEntries() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showErrorSnackBar('Not logged in');
        return;
      }

      final entries = await JournalService.getJournalEntries(userId);

      if (mounted) {
        setState(() {
          _journalEntries = entries;
          _filteredEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load journal entries');
      }
    }
  }

  void _filterEntries() {
    setState(() {
      _filteredEntries = _journalEntries.where((entry) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            (entry.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            entry.content.toLowerCase().contains(_searchQuery.toLowerCase());

        // Category filter
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'shared':
            matchesFilter = entry.isSharedWithCounselor;
            break;
          case 'positive':
            matchesFilter = entry.sentiment?.toLowerCase() == 'positive';
            break;
          case 'negative':
            matchesFilter = entry.sentiment?.toLowerCase() == 'negative';
            break;
          case 'neutral':
            matchesFilter = entry.sentiment?.toLowerCase() == 'neutral';
            break;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _deleteEntry(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to delete "${entry.title ?? (entry.content.isNotEmpty ? entry.content.substring(0, entry.content.length.clamp(0, 20)) : "Untitled entry")}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await JournalService.deleteJournalEntry(entry.journalId);
      if (success) {
        _loadJournalEntries();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully')),
        );
      } else {
        _showErrorSnackBar('Failed to delete entry');
      }
    }
  }

  Future<void> _updateSharingStatus(JournalEntry entry) async {
    final newSharingStatus = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Sharing', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like to share this entry with your counselor?',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Text(
              'Current status: ${entry.isSharedWithCounselor ? "Shared" : "Private"}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep Private',
              style: GoogleFonts.poppins(
                color: entry.isSharedWithCounselor ? Colors.grey[600] : Colors.blue,
                fontWeight: entry.isSharedWithCounselor ? FontWeight.normal : FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Share with Counselor',
              style: GoogleFonts.poppins(
                color: entry.isSharedWithCounselor ? Colors.blue : Colors.green,
                fontWeight: entry.isSharedWithCounselor ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );

    if (newSharingStatus != null && newSharingStatus != entry.isSharedWithCounselor) {
      final success = await JournalService.updateJournalSharingStatus(
        entry.journalId.toString(),
        newSharingStatus,
      );
      
      if (success) {
        _loadJournalEntries();
        Navigator.of(context).pop(); // Close the details modal
        _showErrorSnackBar(
          newSharingStatus 
            ? 'Entry is now shared with counselor' 
            : 'Entry is now private'
        );
      } else {
        _showErrorSnackBar('Failed to update sharing status');
      }
    }
  }

  void _showEntryDetails(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.title ?? 'Journal Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(entry.entryTimestamp),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.isSharedWithCounselor
                          ? Colors.green[100]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.isSharedWithCounselor ? 'Shared' : 'Private',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: entry.isSharedWithCounselor
                            ? Colors.green[700]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    entry.content,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF3A3A50),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (entry.sentiment != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        entry.sentimentEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sentiment: ${entry.sentimentLabel}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateSharingStatus(entry),
                      icon: Icon(
                        entry.isSharedWithCounselor ? Icons.edit_outlined : Icons.share_outlined,
                        color: const Color(0xFF7C83FD),
                      ),
                      label: Text(
                        entry.isSharedWithCounselor ? 'Edit Sharing' : 'Share with Counselor',
                        style: GoogleFonts.poppins(color: const Color(0xFF7C83FD)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C83FD).withOpacity(0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteEntry(entry),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pastelBlue = Color.fromARGB(255, 242, 241, 248);
    const darkText = Color(0xFF3A3A50);

    return Scaffold(
      backgroundColor: pastelBlue,
      appBar: AppBar(
        backgroundColor: pastelBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Mood Journal",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        centerTitle: true,
        actions: [
          const StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Search and Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _filterEntries();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search entries...',
                            hintStyle:
                                GoogleFonts.poppins(color: Colors.grey[600]),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF7C83FD)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Shared', 'shared'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Positive', 'positive'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Neutral', 'neutral'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Negative', 'negative'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Journal Entries List
                  Expanded(
                    child: _filteredEntries.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.book_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty ||
                                          _selectedFilter != 'all'
                                      ? 'No entries match your search'
                                      : 'No mood journal entries yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_searchQuery.isEmpty &&
                                    _selectedFilter == 'all') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the "Write Entry" button to get started!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              return _buildJournalEntryCard(entry);
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('write_journal_entry_fab'),
        onPressed: () {
          Navigator.pushNamed(context, 'student-mood-journal-write').then((_) {
            // Refresh the journal entries when returning from writing
            _loadJournalEntries();
          });
        },
        backgroundColor: const Color(0xFF7C83FD),
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
        _filterEntries();
      },
      selectedColor: const Color(0xFF7C83FD).withOpacity(0.2),
      checkmarkColor: const Color(0xFF7C83FD),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF7C83FD) : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildJournalEntryCard(JournalEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.title ?? entry.content,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.sentiment != null)
                    Text(
                      entry.sentimentEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(entry.entryTimestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Row(
                    children: [
                      if (entry.isSharedWithCounselor)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Shared',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
