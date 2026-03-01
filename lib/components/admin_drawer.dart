import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:breathe_better/controllers/admin_controller.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = AdminController();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('OVERVIEW'),
                  _buildItem(context, icon: Icons.dashboard_rounded, title: 'Dashboard',
                      onTap: () { Navigator.pop(context); Navigator.pushReplacementNamed(context, 'admin-home'); }),
                  _buildLabel('MANAGEMENT'),
                  _buildItem(context, icon: Icons.manage_accounts_rounded, title: 'Users',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, 'admin-users'); }),
                  _buildItem(context, icon: Icons.library_books_rounded, title: 'Mental Health Resources',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, 'admin-resources'); }),
                  _buildItem(context, icon: Icons.air_rounded, title: 'Breathing Exercises',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, 'admin-exercises'); }),
                  _buildItem(context, icon: Icons.phone_in_talk_rounded, title: 'Mental Health Hotlines',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, 'admin-hotlines'); }),
                  _buildItem(context, icon: Icons.wb_sunny_rounded, title: 'Daily Uplifts',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, 'admin-daily-uplifts'); }),
                  _buildItem(context, icon: Icons.quiz_rounded, title: 'Questionnaire',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/admin-questionnaire'); }),
                  _buildLabel('SETTINGS'),
                  _buildItem(context, icon: Icons.settings_rounded, title: 'Settings',
                      onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/settings'); }),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFEEEEEE))),
          _buildLogout(context, adminController),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3D5A99)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(Icons.admin_panel_settings_rounded, size: 32, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Administrator', style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('System Admin', style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 2),
      child: Text(label, style: GoogleFonts.poppins(
          fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFAAAAAA), letterSpacing: 1.2)),
    );
  }

  Widget _buildItem(BuildContext context, {Key? key, required IconData icon, required String title,
      required VoidCallback onTap, Color? iconColor, Color? textColor}) {
    final c = iconColor ?? const Color(0xFF5D5D72);
    final tc = textColor ?? const Color(0xFF3A3A50);
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        horizontalTitleGap: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: c, size: 18),
        ),
        title: Text(title, style: GoogleFonts.poppins(color: tc, fontWeight: FontWeight.w500, fontSize: 14)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogout(BuildContext context, AdminController adminController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        key: const Key('logout_button'),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        horizontalTitleGap: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(9)),
          child: Icon(Icons.logout_rounded, color: Colors.red[400], size: 18),
        ),
        title: Text('Logout', style: GoogleFonts.poppins(
            color: Colors.red[400], fontWeight: FontWeight.w600, fontSize: 14)),
        onTap: () async {
          await adminController.signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        },
      ),
    );
  }
}