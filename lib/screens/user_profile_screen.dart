import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'service_records_screen.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:intl/intl.dart';
import 'admin_notification_composer_screen.dart';
import 'notification_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);
  final Color _textMain = const Color(0xFF0e121b);
  final Color _textSecondary = const Color(0xFF4d6599);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService().getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data;
        final name = userData?['name'] ?? 'User';
        final role = userData?['role'] ?? 'customer';
        final createdAt = userData?['createdAt'] as Timestamp?;
        final dateStr = createdAt != null 
            ? DateFormat('MMM yyyy').format(createdAt.toDate()) 
            : 'Jan 2024';

        return Container(
          color: _backgroundLight,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    children: [
                      _buildProfileCard(context, name, role, dateStr),
                      if (userData?['email'] == 'muhammednihal.k33@gmail.com') ...[
                        const SizedBox(height: 24),
                        _buildAdminTools(context),
                      ],
                      const SizedBox(height: 24),
                      _buildSettings(context, role),
                      const SizedBox(height: 20),
                      _buildLogoutButton(context),
                      const SizedBox(height: 8),
                      const Text(
                        'App Version 1.0.2',
                        style: TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, String name, String role, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000080), Color(0xFF2463eb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2463eb).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const ClipOval(
                  child: Icon(
                    Icons.person,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF2463eb),
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildInfoBadge(role[0].toUpperCase() + role.substring(1)),
                    _buildInfoBadge('Active'),
                    _buildInfoBadge(dateStr),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }



  Widget _buildSettings(BuildContext context, String role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Settings',
              style: TextStyle(
                color: Color(0xFF0e121b),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            iconColor: _primaryColor,
            iconBg: const Color(0xFFeff6ff),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.receipt_long_outlined,
            label: 'My Receipts',
            iconColor: const Color(0xFFea580c),
            iconBg: const Color(0xFFfff7ed),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceRecordsScreen(userRole: role),
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            iconColor: const Color(0xFF6366f1),
            iconBg: const Color(0xFFeef2ff),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            label: 'Privacy & Security',
            iconColor: const Color(0xFF10b981),
            iconBg: const Color(0xFFecfdf5),
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            label: 'Help & Support',
            iconColor: const Color(0xFFa855f7),
            iconBg: const Color(0xFFfaf5ff),
            showBorder: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTools(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate for admin feel
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Admin Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _buildSettingsItem(
            icon: Icons.campaign_rounded,
            label: 'Compose Notification',
            iconColor: Colors.amber,
            iconBg: Colors.amber.withOpacity(0.1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminNotificationComposerScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
    bool showBorder = true,
  }) {
    return Container(
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade50, width: 1),
              ),
            )
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF0e121b),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final AuthService _authService = AuthService();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFdc2626), Color(0xFFef4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.logout, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
