import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/modern_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GasDirectoryScreen extends StatelessWidget {
  const GasDirectoryScreen({super.key});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient blobs for a premium feel
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2463EB).withOpacity(0.05),
              ),
            ),
          ),
          Column(
            children: [
              const ModernHeader(
                title: 'Gas Directory',
                subtitle: 'Official Booking & Support',
                showBackButton: true,
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('gas_providers').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2463EB),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No providers found',
                              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }

                    final providers = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      itemCount: providers.length + 1,
                      itemBuilder: (context, index) {
                        if (index == providers.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _buildSafetyInfo(),
                          );
                        }

                        final data = providers[index].data() as Map<String, dynamic>;
                        final Color brandColor = () {
                          try {
                            String hex = (data['color'] ?? '0xFF2463EB').toString();
                            hex = hex.replaceAll('#', '').replaceAll('0x', '');
                            if (hex.length == 6) hex = 'FF' + hex;
                            return Color(int.parse(hex, radix: 16));
                          } catch (e) {
                            return const Color(0xFF2463EB);
                          }
                        }();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildGasCompanyCard(
                            context: context,
                            name: data['name'] ?? '',
                            subtext: data['subtext'] ?? '',
                            icon: Icons.local_gas_station_rounded,
                            primaryPhone: data['primaryPhone'] ?? '',
                            secondaryPhone: data['secondaryPhone'] ?? '',
                            color: brandColor,
                            imageAsset: _getProviderLogo(data['name'] ?? ''),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _getProviderLogo(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('indane')) return 'assets/indane_logo.png';
    if (lowerName.contains('hp')) return 'assets/hp_logo.png';
    if (lowerName.contains('jio')) return 'assets/jio_logo.png';
    return null;
  }

  Widget _buildGasCompanyCard({
    required BuildContext context,
    required String name,
    required String subtext,
    required IconData icon,
    required String primaryPhone,
    required String secondaryPhone,
    required Color color,
    String? imageAsset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          children: [
            // Top Accent Bar
            Container(height: 6, width: double.infinity, color: color.withOpacity(0.8)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade50),
                        ),
                        child: imageAsset != null
                            ? Image.asset(imageAsset, fit: BoxFit.contain)
                            : Icon(icon, color: color, size: 32),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtext,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          onTap: () => _makeCall(primaryPhone),
                          label: 'Support',
                          icon: Icons.headset_mic_rounded,
                          color: color,
                          isPrimary: true,
                        ),
                      ),
                      if (secondaryPhone.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionBtn(
                            onTap: () => _makeCall(secondaryPhone),
                            label: 'Book Now',
                            icon: Icons.local_mall_rounded,
                            color: color,
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isPrimary ? null : Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF1F2), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFFECACA).withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Safety Guidelines',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _safetyPoint('Check cylinder seals & regulator for leaks.'),
          _safetyPoint('Keep kitchen well ventilated during use.'),
          _safetyPoint('Never use mobile phones near a leak.'),
          _safetyPoint('Always switch off regulator at night.'),
        ],
      ),
    );
  }

  Widget _safetyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
