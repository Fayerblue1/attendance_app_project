import 'package:flutter/material.dart';

class AcademicInfoSection extends StatelessWidget {
  final String waliKelas;
  final String waliKelasPhone;
  final String parentName;
  final String parentPhone;
  final String studentEmail;
  final String studentAddress;
  final String className;

  const AcademicInfoSection({
    super.key,
    this.waliKelas = 'Drs. Bambang Sutrisno, M.Pd',
    this.waliKelasPhone = '081234567890',
    this.parentName = 'Bpk. Bambang Rizky',
    this.parentPhone = '0812-9845-7721',
    this.studentEmail = 'ahmad.rizky@student.sekolah.sch.id',
    this.studentAddress =
        'Jl. Melati No. 14, Tebet, Jakarta Selatan\n(Radius 3.2 km dari SMKN 1)',
    this.className = 'XII MIPA 2',
  });

  void _openWhatsApp(BuildContext context, String name, String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Membuka percakapan WhatsApp dengan $name ($phone)...'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Row(
          children: [
            Icon(Icons.badge_outlined, size: 18, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Text(
              'Informasi Akademik & Wali',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // White Container with Items
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Wali Kelas
              _buildInfoTile(
                icon: Icons.groups_outlined,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF1D4ED8),
                label: 'Wali Kelas $className',
                value: waliKelas,
                trailing: GestureDetector(
                  onTap: () => _openWhatsApp(context, waliKelas, waliKelasPhone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat, size: 13, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'WA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),

              // 2. Orang Tua / Wali Siswa
              _buildInfoTile(
                icon: Icons.family_restroom_rounded,
                iconBg: const Color(0xFFE0E7FF),
                iconColor: const Color(0xFF4F46E5),
                label: 'Orang Tua / Wali Siswa',
                value: parentName,
                subValue: Row(
                  children: [
                    Text(
                      parentPhone,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Notif WA Aktif',
                            style: TextStyle(fontSize: 9.5, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),

              // 3. Akun Google Workspace Sekolah
              _buildInfoTile(
                icon: Icons.alternate_email_rounded,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF0F172A),
                label: 'Akun Google Workspace Sekolah',
                value: studentEmail,
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),

              // 4. Alamat Domisili Siswa
              _buildInfoTile(
                icon: Icons.location_on_outlined,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                label: 'Alamat Domisili Siswa',
                value: studentAddress,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    Widget? subValue,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
                if (subValue != null) ...[
                  const SizedBox(height: 3),
                  subValue,
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

