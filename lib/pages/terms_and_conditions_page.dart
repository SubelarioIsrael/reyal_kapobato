import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 50 && 
        !_hasScrolledToBottom) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
            
          ),
          
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 360;
          final isMediumScreen = constraints.maxWidth < 600;
          final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
          final headerFontSize = isSmallScreen ? 20.0 : 24.0;
          final subtitleFontSize = isSmallScreen ? 14.0 : 16.0;
          final captionFontSize = isSmallScreen ? 12.0 : 14.0;
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C83FD), Color(0xFF5D64D8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'BreatheBetter',
                                style: GoogleFonts.poppins(
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Counselor Access Terms',
                                style: GoogleFonts.poppins(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Please Read Before Creating Your Account',
                              style: GoogleFonts.poppins(
                                fontSize: captionFontSize,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Introduction
                      _buildIntroText(isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Section 1
                      _buildSection(
                        isSmallScreen,
                    '1',
                    'What Data Can Counselors See?',
                    'If you give consent, authorized counselors may view:',
                    [
                      'Your journal entries',
                      'Your daily activities and self-care logs',
                      'Your mood history and emotional check-ins',
                      'Mental health assessments you answer in the app',
                      'Other information you choose to share for counseling purposes',
                    ],
                    footer: 'Counselors will only access data that helps support your mental health.',
                      ),

                      // Section 2
                      _buildSection(
                        isSmallScreen,
                        '2',
                    'Why Do Counselors Need Access?',
                    'Counselors use your data to:',
                    [
                      'Better understand how you are feeling over time',
                      'Track patterns in mood, stress, or behavior',
                      'Give personalized advice and coping strategies',
                      'Help during difficult or high-risk situations',
                    ],
                    footer: 'Your data will never be used for grading, discipline, or academic evaluation.',
                    footerBold: true,
                      ),

                      // Section 3
                      _buildSection(
                        isSmallScreen,
                        '3',
                    'Your Consent',
                    'By creating an account and using BreatheBetter, you are giving permission for counselors to access the data listed above.\n\nYou can choose to limit or withdraw this access later, but doing so may reduce the support counselors can provide.',
                    [],
                      ),

                      // Section 4
                      _buildSection(
                        isSmallScreen,
                        '4',
                    'Privacy and Confidentiality',
                    'Your information is private and confidential.',
                    [
                      'Only authorized counselors can view your data',
                      'Counselors must follow ethical rules and privacy laws',
                      'Your data will not be shared with teachers, administrators, or other students',
                    ],
                    footer: 'Your data will only be shared without your permission if:\n• The law requires it, or\n• There is a serious risk of harm to you or others',
                      ),

                      // Section 5
                      _buildSection(
                        isSmallScreen,
                        '5',
                    'Emergency Situations',
                    'BreatheBetter is not an emergency service.\n\nIf counselors believe there is a serious risk to your safety or to others, they may follow school or institutional emergency procedures, which could include contacting emergency services or designated authorities.',
                    [],
                      ),

                      // Section 6
                      _buildSection(
                        isSmallScreen,
                        '6',
                    'Your Rights as a Student',
                    'You have the right to:',
                    [
                      'Know what data is collected about you',
                      'View your own data in the app',
                      'Ask how your data is being used',
                      'Request changes to your consent, based on school policies',
                    ],
                      ),

                      // Section 7
                      _buildSection(
                        isSmallScreen,
                        '7',
                    'Data Storage and Retention',
                    'Your data will only be stored as long as needed to support your mental health or to meet legal and institutional requirements. After this period, data may be securely deleted or anonymized.',
                    [],
                      ),

                      // Section 8
                      _buildSection(
                        isSmallScreen,
                        '8',
                    'Changes to These Terms',
                    'These terms may be updated from time to time. If important changes are made, you will be notified in the app. Continuing to use BreatheBetter means you accept the updated terms.',
                    [],
                      ),

                      // Section 9
                      _buildSection(
                        isSmallScreen,
                        '9',
                    'Agreement',
                    'By creating an account, you confirm that you:',
                    [
                      'Understand these terms',
                      'Agree to counselor access as described above',
                      'Want to use BreatheBetter for mental health support',
                    ],
                        footer: 'If you do not agree, please do not create an account.',
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 40),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_hasScrolledToBottom)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_downward, size: 16, color: Color(0xFF7C83FD)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Scroll down to read all terms',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: const Color(0xFF7C83FD),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: const BorderSide(color: Color(0xFF7C83FD)),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Disagree',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF7C83FD),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _hasScrolledToBottom
                                  ? () => Navigator.pop(context, true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                backgroundColor: const Color(0xFF7C83FD),
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Agree',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: _hasScrolledToBottom ? Colors.white : Colors.grey.shade500,
                                  ),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntroText(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF7C83FD).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C83FD).withOpacity(0.2)),
      ),
      child: Text(
        'BreatheBetter is a mental health support app. To give you proper guidance and support, your assigned counselor may need to view some of the information you share in the app.\n\nBy creating an account, you agree to the terms below.',
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 13 : 14,
          height: 1.6,
          color: const Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildSection(
    bool isSmallScreen,
    String number,
    String title,
    String content,
    List<String> bulletPoints, {
    String? footer,
    bool footerBold = false,
  }) {
    final numberSize = isSmallScreen ? 28.0 : 32.0;
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final contentFontSize = isSmallScreen ? 13.0 : 14.0;
    final leftPadding = isSmallScreen ? 36.0 : 44.0;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: numberSize,
                height: numberSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C83FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          if (content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: leftPadding),
              child: Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: contentFontSize,
                  height: 1.6,
                  color: const Color(0xFF4A5568),
                ),
              ),
            ),
          if (bulletPoints.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 6 : 8),
            ...bulletPoints.map((point) => Padding(
              padding: EdgeInsets.only(left: leftPadding, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: isSmallScreen ? 5 : 6,
                    height: isSmallScreen ? 5 : 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C83FD),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.poppins(
                        fontSize: contentFontSize,
                        height: 1.6,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          if (footer != null) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            Padding(
              padding: EdgeInsets.only(left: leftPadding),
              child: Text(
                footer,
                style: GoogleFonts.poppins(
                  fontSize: contentFontSize,
                  height: 1.6,
                  color: const Color(0xFF4A5568),
                  fontWeight: footerBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
