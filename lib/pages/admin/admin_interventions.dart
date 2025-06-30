import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminInterventions extends StatefulWidget {
  const AdminInterventions({super.key});

  @override
  State<AdminInterventions> createState() => _AdminInterventionsState();
}

class _AdminInterventionsState extends State<AdminInterventions> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _interventions = [];
  List<Map<String, dynamic>> _recentChats = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadInterventions();
  }

  Future<void> _loadInterventions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load intervention logs
      final interventionsResponse =
          await supabase.from('intervention_logs').select('''
            *,
            users!inner(username, email, user_type)
          ''').order('triggered_at', ascending: false).limit(50);

      // Load recent concerning chat messages
      final chatsResponse = await supabase
          .from('chat_messages')
          .select('''
            *,
            users!inner(username, email, user_type)
          ''')
          .eq('sender', 'user')
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _interventions = List<Map<String, dynamic>>.from(interventionsResponse);
        _recentChats = List<Map<String, dynamic>>.from(chatsResponse);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading interventions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredInterventions {
    if (_selectedFilter == 'all') {
      return _interventions;
    }
    return _interventions.where((intervention) {
      return intervention['intervention_level'] == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Intervention Monitoring",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5D5D72)),
            onPressed: _loadInterventions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterButton('all', 'All'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterButton('moderate', 'Moderate'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFilterButton('high', 'High Risk'),
                      ),
                    ],
                  ),
                ),

                // Statistics cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Interventions',
                          _interventions.length.toString(),
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'High Risk',
                          _interventions
                              .where((i) => i['intervention_level'] == 'high')
                              .length
                              .toString(),
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Today',
                          _interventions
                              .where((i) {
                                final date = DateTime.parse(i['triggered_at']);
                                final today = DateTime.now();
                                return date.year == today.year &&
                                    date.month == today.month &&
                                    date.day == today.day;
                              })
                              .length
                              .toString(),
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Interventions list
                Expanded(
                  child: _filteredInterventions.isEmpty
                      ? Center(
                          child: Text(
                            'No interventions found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredInterventions.length,
                          itemBuilder: (context, index) {
                            final intervention = _filteredInterventions[index];
                            return _buildInterventionCard(intervention);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C83FD) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C83FD) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionCard(Map<String, dynamic> intervention) {
    final isHighRisk = intervention['intervention_level'] == 'high';
    final user = intervention['users'] as Map<String, dynamic>;
    final triggeredAt = DateTime.parse(intervention['triggered_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHighRisk ? Colors.red[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isHighRisk ? 'HIGH RISK' : 'MODERATE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isHighRisk ? Colors.red[700] : Colors.orange[700],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(triggeredAt),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Student: ${user['username']} (${user['email']})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trigger Message:',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                intervention['trigger_message'] ?? 'No message',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
