import 'package:flutter/material.dart';

class TeacherQuickActionsSection extends StatelessWidget {
  const TeacherQuickActionsSection({super.key});

  void _showManualAttendanceDialog(BuildContext context) {
    final studentNameController = TextEditingController();
    String selectedStatus = 'Hadir';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (bottomCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 22,
            bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.how_to_reg_rounded, color: Color(0xFF4F46E5), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Input Presensi Manual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Gunakan fitur ini jika siswa mengalami kendala perangkat atau lupa absensi.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: studentNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Siswa atau NIS',
                  hintText: 'Misal: Bima Arya Pangestu (222310106)',
                  prefixIcon: const Icon(Icons.person_search_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Status Kehadiran:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildStatusChoiceChip('Hadir', selectedStatus, (val) {
                    setModalState(() => selectedStatus = val);
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChoiceChip('Izin', selectedStatus, (val) {
                    setModalState(() => selectedStatus = val);
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChoiceChip('Sakit', selectedStatus, (val) {
                    setModalState(() => selectedStatus = val);
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChoiceChip('Dispensasi', selectedStatus, (val) {
                    setModalState(() => selectedStatus = val);
                  }),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    final name = studentNameController.text.trim();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF4F46E5),
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Presensi manual berhasil dicatat: ${name.isNotEmpty ? name : "Siswa"} dinyatakan $selectedStatus.',
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Simpan Presensi Manual',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChoiceChip(
      String label, String currentSelected, Function(String) onSelected) {
    final isSelected = label == currentSelected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      onSelected: (_) => onSelected(label),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: Color(0xFF0D9488), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Broadcast Notifikasi Kelas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Pesan akan disiarkan ke seluruh aplikasi PresensiKu siswa dan wali murid di kelas XII RPL 1.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Judul Pengumuman',
                hintText: 'Misal: Pengingat Jadwal Ujian Praktik Besok',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Isi Pesan Siaran',
                hintText: 'Tuliskan instruksi atau pengingat untuk seluruh kelas...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notifikasi siaran berhasil dikirim ke 36 siswa dan orang tua.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                label: const Text(
                  'Kirim Broadcast Sekarang',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEA580C)),
            SizedBox(width: 8),
            Text('Unduh Rekap Presensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rekapitulasi resmi presensi kelas XII RPL 1 (SMK Negeri 1 Jakarta):',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
            SizedBox(height: 10),
            Text('• Format: Dokumen PDF Resmi\n• Tanda Tangan Digital Kepala Sekolah & Wali Kelas\n• Rekapitulasi: Bulan Berjalan & Semester Ganjil 2024/2025',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFFEA580C),
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Mengunduh Rekap_Presensi_XII_RPL_1_Oktober_2024.pdf...',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
            label: const Text('Unduh PDF', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Row(
          children: [
            Icon(Icons.bolt_rounded, size: 20, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Text(
              'Aksi & Layanan Cepat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3 Cards
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_add_alt_1_rounded,
                iconColor: const Color(0xFF4F46E5),
                bgColor: const Color(0xFFEEF2FF),
                title: 'Input Absen\nManual',
                onTap: () => _showManualAttendanceDialog(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                icon: Icons.campaign_rounded,
                iconColor: const Color(0xFF0D9488),
                bgColor: const Color(0xFFECFDF5),
                title: 'Broadcast\nNotifikasi',
                onTap: () => _showBroadcastDialog(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionCard(
                icon: Icons.file_download_outlined,
                iconColor: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFF7ED),
                title: 'Unduh Rekap\n(PDF)',
                onTap: () => _showDownloadReportDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

