import 'package:flutter/material.dart';

class LeaveVerificationItem {
  final String id;
  final String initials;
  final String studentName;
  final String nis;
  final String className;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final String period;
  final String reason;
  final String attachmentName;
  final bool isPdf;
  String status; // 'pending', 'approved', 'rejected'

  LeaveVerificationItem({
    required this.id,
    required this.initials,
    required this.studentName,
    required this.nis,
    required this.className,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.period,
    required this.reason,
    required this.attachmentName,
    required this.isPdf,
    this.status = 'pending',
  });
}

class TeacherLeaveVerificationSection extends StatefulWidget {
  final VoidCallback onViewAll;

  const TeacherLeaveVerificationSection({
    super.key,
    required this.onViewAll,
  });

  @override
  State<TeacherLeaveVerificationSection> createState() =>
      _TeacherLeaveVerificationSectionState();
}

class _TeacherLeaveVerificationSectionState
    extends State<TeacherLeaveVerificationSection> {
  late List<LeaveVerificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      LeaveVerificationItem(
        id: '1',
        initials: 'AR',
        studentName: 'Ahmad Rizky Pratama',
        nis: '222310104',
        className: 'XII RPL 1',
        badgeText: 'Sakit (2 Hari)',
        badgeColor: const Color(0xFFEFF6FF),
        badgeTextColor: const Color(0xFF1D4ED8),
        period: '24 - 25 Okt 2024',
        reason:
            '"Demam tinggi & flu berat sejak semalam. Istirahat dari rekomendasi dr. Hendra (Klinik Sehat Medika)."',
        attachmentName: 'Surat_Dokter_Hendra.pdf • Terverifikasi Barcode Digital',
        isPdf: true,
      ),
      LeaveVerificationItem(
        id: '2',
        initials: 'SN',
        studentName: 'Siti Nurhaliza',
        nis: '222310108',
        className: 'XII RPL 1',
        badgeText: 'Izin (1 Hari)',
        badgeColor: const Color(0xFFEFF6FF),
        badgeTextColor: const Color(0xFF2563EB),
        period: '24 Okt 2024',
        reason:
            '"Menghadiri akad nikah kakak kandung di Bandung, Jawa Barat. Surat izin bertandatangan orang tua terlampir."',
        attachmentName: 'Surat_Pernyataan_Ortu.jpg',
        isPdf: false,
      ),
      LeaveVerificationItem(
        id: '3',
        initials: 'DS',
        studentName: 'Dimas Setiawan',
        nis: '222310109',
        className: 'XII RPL 1',
        badgeText: 'Dispensasi LKS',
        badgeColor: const Color(0xFFD1FAE5),
        badgeTextColor: const Color(0xFF065F46),
        period: '24 Okt 2024 (Hari Ini)',
        reason:
            '"Bimbingan intensif persiapan LKS Bidang Web Technologies di Gedung Disdik DKI Jakarta."',
        attachmentName: '',
        isPdf: false,
      ),
    ];
  }

  int get _pendingCount =>
      _items.where((element) => element.status == 'pending').length;

  void _handleApprove(LeaveVerificationItem item) {
    setState(() {
      item.status = 'approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Pengajuan ${item.studentName} berhasil disetujui.'),
          ],
        ),
      ),
    );
  }

  void _handleReject(LeaveVerificationItem item) {
    setState(() {
      item.status = 'rejected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Pengajuan ${item.studentName} telah ditolak.'),
          ],
        ),
      ),
    );
  }

  void _showDocumentPreview(LeaveVerificationItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      item.isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: item.isPdf
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF2563EB),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pratinjau Dokumen Lampiran',
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
            const SizedBox(height: 14),

            // Document Preview Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(
                    item.isPdf
                        ? Icons.description_rounded
                        : Icons.photo_library_rounded,
                    size: 56,
                    color: const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.attachmentName.split(' • ').first,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dokumen Resmi Sekolah • Terenkripsi QR Verifikasi',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Tanda Tangan & Cap Digital Valid',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup Pratinjau',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        // Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Verifikasi Izin & Sakit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                if (_pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_pendingCount Perlu Tindakan',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            GestureDetector(
              onTap: widget.onViewAll,
              child: const Row(
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF1D4ED8),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List Cards
        ..._items.map((item) => _buildVerificationCard(item)),
      ],
    );
  }

  Widget _buildVerificationCard(LeaveVerificationItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name/NIS + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.initials,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: ${item.nis} • ${item.className}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.badgeColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.badgeTextColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.badgeText.contains('Sakit')
                          ? Icons.medical_services_outlined
                          : Icons.assignment_outlined,
                      size: 11.5,
                      color: item.badgeTextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.badgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: item.badgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Period Row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                'Periode: ${item.period}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Reason Quote
          Text(
            item.reason,
            style: const TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),

          // Attachment Box (if present)
          if (item.attachmentName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    item.isPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    size: 18,
                    color: item.isPdf
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.attachmentName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showDocumentPreview(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.isPdf ? 'Buka' : 'Lihat',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Status / Buttons
          if (item.status == 'approved')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Disetujui Guru',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            )
          else if (item.status == 'rejected')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Pengajuan Ditolak',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleReject(item),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleApprove(item),
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      item.badgeText.contains('Dispensasi')
                          ? 'Setujui Dispensasi'
                          : 'Setujui Izin',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

