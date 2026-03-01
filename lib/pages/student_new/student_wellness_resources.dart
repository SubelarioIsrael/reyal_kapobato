import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_wellness_resources_controller.dart';

class StudentWellnessResources extends StatefulWidget {
  const StudentWellnessResources({super.key});

  @override
  State<StudentWellnessResources> createState() =>
      _StudentWellnessResourcesState();
}

class _StudentWellnessResourcesState extends State<StudentWellnessResources>
    with SingleTickerProviderStateMixin {
  final StudentWellnessResourcesController _controller =
      StudentWellnessResourcesController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          _showErrorDialog('Could not open the link');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Invalid URL');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784))
                    .withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784))
                          .withOpacity(0.2),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    if (resource['tags'] != null &&
                        resource['tags'].toString().isNotEmpty) ...[
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isVideo
                                            ? const Color(0xFF7C83FD)
                                            : const Color(0xFF81C784))
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isVideo
                                          ? const Color(0xFF7C83FD)
                                          : const Color(0xFF81C784),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag.trim(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isVideo
                                          ? const Color(0xFF7C83FD)
                                          : const Color(0xFF81C784),
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
                    backgroundColor:
                        isVideo ? const Color(0xFF7C83FD) : const Color(0xFF81C784),
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
          onPressed: () async {
            await Navigator.of(context).maybePop();
          },
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
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _controller.videos,
                  builder: (_, v, __) => Tab(
                    text: v.isEmpty ? 'Videos' : 'Videos (${v.length})',
                  ),
                ),
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _controller.articles,
                  builder: (_, a, __) => Tab(
                    text: a.isEmpty ? 'Articles' : 'Articles (${a.length})',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: const StudentDrawer(),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, _) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _controller.videos,
                builder: (_, videos, __) =>
                    _buildTabContent(videos, true),
              ),
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _controller.articles,
                builder: (_, articles, __) =>
                    _buildTabContent(articles, false),
              ),
            ],
          );
        },
      ),
    );
  }
}
