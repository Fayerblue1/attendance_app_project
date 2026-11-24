import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../widgets/student_id_card.dart';
import '../widgets/academic_info_section.dart';
import '../widgets/attendance_preferences_section.dart';

class ProfilePage extends StatelessWidget {
  final UserModel? userProfile;
  final VoidCallback onSignOut;

  const ProfilePage({
    super.key,
    required this.userProfile,
    required this.onSignOut,
  });

  void _showHelpFaq(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Text('Pusat Bantuan PresensiKu', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAQ & Bantuan Teknis:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '1. Berapa batas radius presensi gerbang sekolah?\n'
              'Batas radius adalah 150 meter dari titik pusat gerbang utama SMKN 1 Jakarta.\n\n'
              '2. Bagaimana jika kamera selfie gagal memuat?\n'
              'Pastikan izin kamera dan GPS/Lokasi perangkat telah diizinkan pada pengaturan aplikasi.\n\n'
              '3. Kontak Bantuan Admin TU:\n'
              'Email: tu@smkn1jakarta.sch.id\n'
              'WhatsApp: 0812-9845-7721',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF1D4ED8))),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Kebijakan Privasi & Biometrik', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            '1. Pengolahan Data Biometrik & Foto\n'
            'Data foto selfie dan titik koordinat GPS diproses secara terenkripsi (SSL 256-Bit) dan hanya digunakan untuk verifikasi kehadiran resmi sekolah.\n\n'
            '2. Kerahasiaan Data Siswa\n'
            'Data NIS, NISN, serta rekap absensi dilindungi dan tidak disebarluaskan ke pihak ketiga tanpa izin pihak sekolah dan wali murid.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = (userProfile?.name.isNotEmpty == true)
        ? userProfile!.name
        : 'Ahmad Rizky Pratama';
    final nisNumber = (userProfile?.nis.isNotEmpty == true)
        ? userProfile!.nis
        : '210845';
    const nisnNumber = '0071239841'; // Standard NISN display
    final classInfo = (userProfile?.classId.isNotEmpty == true)
        ? userProfile!.classId
        : 'XII MIPA 2';
    final email = (userProfile?.email.isNotEmpty == true)
        ? userProfile!.email
        : 'ahmad.rizky@student.sekolah.sch.id';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. PROFILE HEADER CARD (Foto, Badges, Nama, Action)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar with Camera Edit Badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: userProfile?.photoUrl.isNotEmpty == true
                            ? Image.network(
                                userProfile!.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                              )
                            : _buildAvatarPlaceholder(),
                      ),
                    ),
                    // Camera icon button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur ubah foto profil siswa...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pill Badges: Siswa Aktif • XII MIPA 2 & Dapodik Kemdikbud
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Siswa Aktif • $classInfo',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 12, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 4),
                          Text(
                            'Dapodik Kemdikbud',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Full Student Name
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // NIS & NISN
                Text(
                  'NIS: $nisNumber • NISN: $nisnNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Row: [Kartu Pelajar Digital] & [Copy Button]
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Membuka Kartu Tanda Pelajar Digital...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.badge_outlined, color: Colors.white, size: 18),
                          label: const Text(
                            'Kartu Pelajar Digital',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF475569)),
                        tooltip: 'Salin NIS & NISN',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'NIS: $nisNumber, NISN: $nisnNumber'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF10B981),
                              content: Text('Nomor NIS & NISN berhasil disalin ke clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. KARTU TANDA PELAJAR DIGITAL (KOMPONEN MANDIRI)
          StudentIdCard(
            studentName: studentName,
            nis: nisNumber,
            className: classInfo,
          ),
          const SizedBox(height: 18),

          // 3. INFORMASI AKADEMIK & WALI (KOMPONEN MANDIRI)
          AcademicInfoSection(
            className: classInfo,
            studentEmail: email,
          ),
          const SizedBox(height: 18),

          // 4. PENGATURAN & PREFERENSI PRESENSI (KOMPONEN MANDIRI)
          AttendancePreferencesSection(
            userEmail: email,
          ),
          const SizedBox(height: 18),

          // 5. HELP & PRIVACY SECTION
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                  title: const Text(
                    'Pusat Bantuan & FAQ Presensi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF94A3B8)),
                  onTap: () => _showHelpFaq(context),
                ),
                const Divider(height: 1, indent: 48),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: const Icon(Icons.lock_person_outlined, color: Color(0xFF059669), size: 20),
                  title: const Text(
                    'Kebijakan Privasi & Data Biometrik',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                  onTap: () => _showPrivacyPolicy(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 6. KELUAR DARI AKUN (RED SOFT BUTTON)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2), // Soft pink/red
                elevation: 0,
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 19),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 7. FOOTER & ENKRIPSI
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 12, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'PresensiKu v2.4.0 (Build 384) • Terenkripsi SSL 256-Bit',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Dikembangkan oleh Tim IT SMK Negeri 1 Jakarta © 2024',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.person, size: 54, color: Color(0xFF64748B)),
      ),
    );
  }
}

