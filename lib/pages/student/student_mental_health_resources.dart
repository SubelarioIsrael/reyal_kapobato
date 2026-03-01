import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

class StudentMentalHealthResources extends StatefulWidget {
  const StudentMentalHealthResources({super.key});

  @override
  State<StudentMentalHealthResources> createState() =>
      _StudentMentalHealthResourcesState();
}

class _StudentMentalHealthResourcesState
    extends State<StudentMentalHealthResources>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> articles = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    try {
      final response = await Supabase.instance.client
          .from('mental_health_resources')
          .select()
          .order('title');

      if (mounted) {
        setState(() {
          videos = (response as List)
              .where((resource) => resource['resource_type'] == 'video')
              .map((resource) => resource as Map<String, dynamic>)
              .toList();
          articles = (response as List)
              .where((resource) => resource['resource_type'] == 'article')
              .map((resource) => resource as Map<String, dynamic>)
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading resources. Please try again later.'),
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL')),
        );
      }
    }
  }

  void _showResourceDetails(Map<String, dynamic> resource) {
    final isVideo = resource['resource_type'] == 'video';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784)).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784)).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVideo ? Icons.play_circle : Icons.article,
                      color: isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isVideo ? 'Video Resource' : 'Article',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF3A3A50)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      resource['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    if (resource['description'] != null &&
                        resource['description'].toString().isNotEmpty) ...[
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Tags
                    if (resource['tags'] != null && resource['tags'].toString().isNotEmpty) ...[
                      Text(
                        'Tags',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (resource['tags'] as String)
                            .split(',')
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784)).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Action Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _launchURL(resource['media_url']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.play_arrow : Icons.open_in_new,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isVideo ? 'Watch Video' : 'Read Article',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _extractYouTubeId(String url) {
    final regex = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})',
    );
    return regex.firstMatch(url)?.group(1);
  }

  String _extractDomain(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final isVideo = resource['resource_type'] == 'video';
    final String url = (resource['media_url'] ?? '').toString();
    final String? youtubeId = isVideo ? _extractYouTubeId(url) : null;
    final String? description =
        resource['description']?.toString().isNotEmpty == true
            ? resource['description'].toString()
            : null;
    final String? tagsRaw =
        resource['tags']?.toString().isNotEmpty == true
            ? resource['tags'].toString()
            : null;
    final accentColor =
        isVideo ? const Color(0xFF7C83FD) : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showResourceDetails(resource),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: thumbnail (video) or icon (article)
                if (isVideo)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        youtubeId != null
                            ? Image.network(
                                'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg',
                                width: 108, height: 74, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 108, height: 74,
                                  color: const Color(0xFF7C83FD).withOpacity(0.12),
                                  child: const Icon(Icons.video_library_rounded,
                                      color: Color(0xFF7C83FD), size: 28),
                                ),
                              )
                            : Container(
                                width: 108, height: 74,
                                color: const Color(0xFF7C83FD).withOpacity(0.12),
                                child: const Icon(Icons.video_library_rounded,
                                    color: Color(0xFF7C83FD), size: 28),
                              ),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.article_rounded, color: accentColor, size: 26),
                  ),
                const SizedBox(width: 12),
                // Right: text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50), height: 1.3,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (isVideo)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF0000),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('YouTube',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 9, fontWeight: FontWeight.bold)),
                        )
                      else
                        Text(
                          _extractDomain(url),
                          style: GoogleFonts.poppins(
                            fontSize: 11, color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.grey[500], height: 1.4,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tagsRaw != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 5, runSpacing: 4,
                          children: tagsRaw.split(',').take(2)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.09),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(tag.trim(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10, color: accentColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isVideo
                              ? Icons.videocam_rounded
                              : Icons.article_rounded,
                          color: accentColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _extractDomain(url),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded,
                          size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),

              // ── Text body ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (tagsRaw != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tagsRaw
                            .split(',')
                            .take(3)
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.09),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showResourceDetails(resource),
                        icon: Icon(
                          isVideo
                              ? Icons.play_arrow_rounded
                              : Icons.menu_book_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isVideo ? 'Watch Video' : 'Read Article',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
      List<Map<String, dynamic>> resources, bool isVideo) {
    if (resources.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideo
                    ? Icons.videocam_off_rounded
                    : Icons.article_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No ${isVideo ? 'videos' : 'articles'} available yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check back later for new content',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: resources.length,
      itemBuilder: (context, index) =>
          _buildResourceCard(resources[index]),
    );
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
          'Wellness Resources',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [StudentNotificationButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color.fromARGB(255, 242, 241, 248),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF7C83FD),
              unselectedLabelColor: const Color(0xFF9E9E9E),
              labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500, fontSize: 14),
              indicatorColor: const Color(0xFF7C83FD),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  text: videos.isEmpty
                      ? 'Videos'
                      : 'Videos (${videos.length})',
                ),
                Tab(
                  text: articles.isEmpty
                      ? 'Articles'
                      : 'Articles (${articles.length})',
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const StudentDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(videos, true),
                _buildTabContent(articles, false),
              ],
            ),
    );
  }
}
