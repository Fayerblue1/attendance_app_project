import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendancePreferencesSection extends StatefulWidget {
  final String userEmail;

  const AttendancePreferencesSection({
    super.key,
    required this.userEmail,
  });

  @override
  State<AttendancePreferencesSection> createState() =>
      _AttendancePreferencesSectionState();
}

class _AttendancePreferencesSectionState
    extends State<AttendancePreferencesSection> {
  bool _morningReminder = true;
  bool _afternoonReminder = true;

  void _showChangePasswordDialog() {
    final emailController = TextEditingController(text: widget.userEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Text('Ubah Kata Sandi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tautan reset kata sandi baru akan dikirimkan ke email terdaftar Anda:',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Alamat Email',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF10B981),
                        content: Text('Tautan ubah kata sandi berhasil dikirim ke $email'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFFDC2626),
                        content: Text('Gagal mengirim tautan reset: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Kirim Tautan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _downloadRekapPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1D4ED8),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.download_done_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mengunduh Rekap Presensi Semester Ganjil 2024/2025 (PDF)...',
              ),
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
            Icon(Icons.tune_rounded, size: 18, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Text(
              'Pengaturan & Preferensi Presensi',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Settings Container
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
              // 1. Pengingat Presensi Pagi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alarm_on_rounded, color: Color(0xFF1D4ED8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengingat Presensi Pagi',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bunyikan alarm pukul 06.30 WIB',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _morningReminder,
                      activeColor: const Color(0xFF1D4ED8),
                      onChanged: (val) {
                        setState(() => _morningReminder = val);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),

              // 2. Notifikasi Waktu Pulang
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi Waktu Pulang',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Saat bel sekolah usai (15.00 WIB)',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _afternoonReminder,
                      activeColor: const Color(0xFF1D4ED8),
                      onChanged: (val) {
                        setState(() => _afternoonReminder = val);
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),

              // 3. Ubah Kata Sandi Akun
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: Color(0xFF475569), size: 20),
                ),
                title: const Text(
                  'Ubah Kata Sandi Akun',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                subtitle: const Text(
                  'Terakhir diperbarui 45 hari yang lalu',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
                onTap: _showChangePasswordDialog,
              ),
              const Divider(height: 1, indent: 64, endIndent: 16),

              // 4. Unduh Rekap Presensi Semester
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF1D4ED8), size: 20),
                ),
                title: const Text(
                  'Unduh Rekap Presensi Semester',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                subtitle: const Text(
                  'Format PDF resmi ditandatangani digital',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF1D4ED8)),
                  onPressed: _downloadRekapPdf,
                ),
                onTap: _downloadRekapPdf,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

