import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

// ─── Model data untuk satu entri catatan harian ───
class _DailyRecord {
  final String date; // 'YYYY-MM-DD'
  final String dayLabel; // 'Kamis, 24 Okt 2024'
  final String location;
  final String checkInTime;
  final String checkOutTime;
  final String status; // 'Tepat Waktu', 'Terlambat 7 Menit', 'Sakit (Dokter)', 'Izin', 'Alpa'
  final String category; // 'hadir', 'terlambat', 'izin_sakit', 'alpa'
  final bool faceIdValid;
  final String radiusInfo;
  final String? diagnosis;
  final String? attachmentName;
  final String? dispensasi;

  const _DailyRecord({
    required this.date,
    required this.dayLabel,
    required this.location,
    required this.checkInTime,
    required this.checkOutTime,
    required this.status,
    required this.category,
    this.faceIdValid = true,
    this.radiusInfo = 'Radius 42m',
    this.diagnosis,
    this.attachmentName,
    this.dispensasi,
  });
}

class HistoryPage extends StatefulWidget {
  final Stream<QuerySnapshot>? attendanceStream;
  final UserModel? userProfile;

  const HistoryPage({
    super.key,
    required this.attendanceStream,
    this.userProfile,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // ─── State ───
  late DateTime _selectedMonth;
  int? _selectedDay; // null = tidak ada tanggal yg dipilih
  int _selectedFilterIndex = 0; // 0=Semua, 1=Hadir, 2=Terlambat, 3=Izin/Sakit

  // Contoh data demo (akan digantikan data Firestore jika tersedia)
  final List<_DailyRecord> _demoRecords = const [
    _DailyRecord(
      date: '2024-10-24',
      dayLabel: 'Kamis, 24 Okt 2024',
      location: 'SMK Negeri 1 Jakarta • Kampus Pusat',
      checkInTime: '06:45',
      checkOutTime: '15:35',
      status: 'Tepat Waktu',
      category: 'hadir',
      radiusInfo: 'Radius 42m',
    ),
    _DailyRecord(
      date: '2024-10-23',
      dayLabel: 'Rabu, 23 Okt 2024',
      location: 'SMK Negeri 1 Jakarta • Gedung Lab A',
      checkInTime: '06:48',
      checkOutTime: '15:30',
      status: 'Tepat Waktu',
      category: 'hadir',
      dispensasi: 'Ekskul Robotik (15:30 - 17:00 WIB)',
    ),
    _DailyRecord(
      date: '2024-10-22',
      dayLabel: 'Selasa, 22 Okt 2024',
      location: 'SMK Negeri 1 Jakarta • Kampus Pusat',
      checkInTime: '06:40',
      checkOutTime: '15:32',
      status: 'Tepat Waktu',
      category: 'hadir',
    ),
    _DailyRecord(
      date: '2024-10-18',
      dayLabel: 'Jumat, 18 Okt 2024',
      location: 'Diwakili oleh Wali Kelas: Drs. Bambang S.',
      checkInTime: '--:--',
      checkOutTime: '--:--',
      status: 'Sakit (Dokter)',
      category: 'izin_sakit',
      diagnosis: 'Diagnosa: Sakit Demam & Flu',
      attachmentName: 'Surat_keterangan_sakit.pdf',
    ),
    _DailyRecord(
      date: '2024-10-16',
      dayLabel: 'Selasa, 16 Okt 2024',
      location: 'SMK Negeri 1 Jakarta • Gerbang Depan',
      checkInTime: '07:07',
      checkOutTime: '15:30',
      status: 'Terlambat 7 Menit',
      category: 'terlambat',
      radiusInfo: 'Radius 38m',
      dispensasi: 'Alasan Keterlambatan:\nGangguan sinyal KRL Stasiun Manggarai – Juanda\n(Diverifikasi Tim Tertib)',
    ),
  ];

  // Status kalender per tanggal (day -> category)
  final Map<int, String> _calendarStatus = {
    1: 'hadir', 2: 'hadir', 3: 'hadir', 4: 'hadir',
    7: 'hadir', 8: 'hadir', 9: 'hadir', 10: 'hadir', 11: 'hadir',
    14: 'hadir', 15: 'hadir', 16: 'terlambat', 17: 'hadir', 18: 'izin_sakit',
    21: 'hadir', 22: 'hadir', 23: 'hadir', 24: 'hadir', 25: 'hadir',
    28: 'hadir', 29: 'hadir', 30: 'hadir', 31: 'hadir',
  };

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _shortMonthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<String> _dayHeaders = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(2024, 10); // Oktober 2024 sesuai mockup
  }

  int get _totalHadir => _calendarStatus.values.where((v) => v == 'hadir').length;
  int get _totalTerlambat => _calendarStatus.values.where((v) => v == 'terlambat').length;
  int get _totalIzinSakit => _calendarStatus.values.where((v) => v == 'izin_sakit').length;
  int get _totalSemua => _calendarStatus.length;

  double get _kehadiranPct {
    if (_totalSemua == 0) return 0;
    return ((_totalHadir + _totalTerlambat) / _totalSemua) * 100;
  }

  List<_DailyRecord> get _filteredRecords {
    switch (_selectedFilterIndex) {
      case 1:
        return _demoRecords.where((r) => r.category == 'hadir').toList();
      case 2:
        return _demoRecords.where((r) => r.category == 'terlambat').toList();
      case 3:
        return _demoRecords.where((r) => r.category == 'izin_sakit').toList();
      default:
        return _demoRecords;
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDay = null;
    });
  }

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Text('Unduh Riwayat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Unduh rekap riwayat kehadiran bulan ${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year} dalam format PDF?',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1D4ED8),
                  behavior: SnackBarBehavior.floating,
                  content: Text(
                    'Mengunduh Rekap_Kehadiran_${_monthNames[_selectedMonth.month - 1]}_${_selectedMonth.year}.pdf...',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
            label: const Text('Unduh PDF', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSanggahanDialog() {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 22,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.report_problem_rounded, color: Color(0xFFF59E0B), size: 22),
                SizedBox(width: 8),
                Text(
                  'Ajukan Sanggahan Data Presensi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Jelaskan ketidaksesuaian data yang ingin Anda ajukan. Sanggahan akan ditinjau oleh Guru BK / Wali Kelas Anda dalam 2×24 jam.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Misal: Tanggal 16 Okt saya sebenarnya hadir tepat waktu, bukti CCTV bisa dicek...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                      content: Text('Sanggahan berhasil diajukan. Menunggu tinjauan Guru/Wali Kelas.'),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                label: const Text('Kirim Sanggahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classId = widget.userProfile?.classId.isNotEmpty == true
        ? widget.userProfile!.classId
        : 'XII RPL 1';
    final monthName = _monthNames[_selectedMonth.month - 1];
    final year = _selectedMonth.year;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════
          // 1. HEADER: Riwayat Kehadiran + Badge Aktif Smt Ganjil
          // ═══════════════════════════════════════════════════
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, size: 20, color: Color(0xFF1D4ED8)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Kehadiran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pantau rekam jejak presensi, geolokasi, dan kedisiplinan Anda.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 11, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Aktif Smt Ganjil',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════
          // 2. MONTH SELECTOR: < Oktober 2024 > + Unduh
          // ═══════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: _prevMonth,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 6),
                      Text(
                        '$monthName $year',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _nextMonth,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF334155)),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: _showDownloadDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.download_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Unduh',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════
          // 3. INFO ROW: Tahun Ajaran + Kelas + Ganti Periode
          // ═══════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tahun Ajaran $year/${year + 1} • $classId',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Ganti Periode akan tersedia pada pembaruan berikutnya.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Ganti Periode ▸',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════
          // 4. KALENDER KEHADIRAN
          // ═══════════════════════════════════════════════════
          _buildCalendarCard(),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════
          // 5. RINGKASAN METRIK (2x2 Grid)
          // ═══════════════════════════════════════════════════
          _buildSummaryMetrics(),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════
          // 6. FILTER TABS: Semua | Hadir | Terlambat | Izin/Sakit
          // ═══════════════════════════════════════════════════
          _buildFilterTabs(),
          const SizedBox(height: 14),

          // ═══════════════════════════════════════════════════
          // 7. CATATAN HARIAN (Daftar Kartu)
          // ═══════════════════════════════════════════════════
          _buildSectionTitle('Catatan Harian', 'Terbaru ke Terlama'),
          const SizedBox(height: 10),
          ..._filteredRecords.map((record) => _buildDailyRecordCard(record)),
          const SizedBox(height: 16),

          // ═══════════════════════════════════════════════════
          // 8. BANNER SANGGAHAN
          // ═══════════════════════════════════════════════════
          _buildSanggahanBanner(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //   KALENDER KEHADIRAN (Grid Bulanan)
  // ══════════════════════════════════════════════════════════════
  Widget _buildCalendarCard() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    // Hari pertama bulan: 1=Mon ... 7=Sun
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    final today = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == today.year && _selectedMonth.month == today.month;

    // Hitung total hari efektif (kecuali Sabtu & Minggu)
    int hariEfektif = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final wd = DateTime(_selectedMonth.year, _selectedMonth.month, d).weekday;
      if (wd < 6) hariEfektif++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Kalender Kehadiran + Hari Efektif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 16, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 6),
                  Text(
                    'Kalender Kehadiran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$hariEfektif Hari Efektif',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day headers: Sen Sel Rab Kam Jum Sab Min
          Row(
            children: _dayHeaders.map((d) {
              final isWeekend = d == 'Sab' || d == 'Min';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isWeekend ? const Color(0xFFDC2626) : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          _buildCalendarGrid(daysInMonth, firstWeekday, isCurrentMonth, today),
          const SizedBox(height: 12),

          // Legend row
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday, bool isCurrentMonth, DateTime today) {
    final List<Widget> rows = [];
    int dayCounter = 1;
    // firstWeekday: 1=Mon=col0, ..., 7=Sun=col6
    final startOffset = firstWeekday - 1;

    for (int week = 0; week < 6; week++) {
      if (dayCounter > daysInMonth) break;
      final List<Widget> cells = [];
      for (int col = 0; col < 7; col++) {
        final cellIndex = week * 7 + col;
        if (cellIndex < startOffset || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 36)));
        } else {
          final d = dayCounter;
          final isToday = isCurrentMonth && d == today.day;
          final isSelected = _selectedDay == d;
          final isWeekend = col >= 5;
          final status = _calendarStatus[d]; // null = weekend/libur

          cells.add(
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = (_selectedDay == d) ? null : d;
                  });
                },
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF1D4ED8)
                        : isSelected
                            ? const Color(0xFFDBEAFE)
                            : _getCalendarCellBg(status, isWeekend),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: const Color(0xFF1D4ED8), width: 2)
                        : isSelected
                            ? Border.all(color: const Color(0xFF1D4ED8), width: 1.5)
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      '$d',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isToday
                            ? Colors.white
                            : isWeekend && status == null
                                ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                                : _getCalendarTextColor(status),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(Row(children: cells));
    }
    return Column(children: rows);
  }

  Color _getCalendarCellBg(String? status, bool isWeekend) {
    if (status == null) {
      return isWeekend ? const Color(0xFFFEF2F2) : Colors.transparent;
    }
    switch (status) {
      case 'hadir':
        return const Color(0xFFECFDF5);
      case 'terlambat':
        return const Color(0xFFFEF3C7);
      case 'izin_sakit':
        return const Color(0xFFEFF6FF);
      case 'alpa':
        return const Color(0xFFFEE2E2);
      default:
        return Colors.transparent;
    }
  }

  Color _getCalendarTextColor(String? status) {
    if (status == null) return const Color(0xFF94A3B8);
    switch (status) {
      case 'hadir':
        return const Color(0xFF059669);
      case 'terlambat':
        return const Color(0xFFD97706);
      case 'izin_sakit':
        return const Color(0xFF2563EB);
      case 'alpa':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF334155);
    }
  }

  Widget _buildCalendarLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendDot(const Color(0xFF059669), const Color(0xFFECFDF5), 'Hadir'),
        _legendDot(const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'Izin/Sakit'),
        _legendDot(const Color(0xFFD97706), const Color(0xFFFEF3C7), 'Telat'),
        _legendDot(const Color(0xFFDC2626), const Color(0xFFFEF2F2), 'Libur/Weekend'),
      ],
    );
  }

  Widget _legendDot(Color dotColor, Color bgColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: dotColor, width: 1.2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: dotColor)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //   RINGKASAN METRIK (2x2)
  // ══════════════════════════════════════════════════════════════
  Widget _buildSummaryMetrics() {
    final pctStr = _kehadiranPct.toStringAsFixed(0);
    final String kehadiranLabel = _kehadiranPct >= 90
        ? 'Baik'
        : _kehadiranPct >= 75
            ? 'Cukup'
            : 'Perlu Perhatian';
    final Color kehadiranColor = _kehadiranPct >= 90
        ? const Color(0xFF059669)
        : _kehadiranPct >= 75
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildMetricTile(
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFECFDF5),
                label: 'Total Hadir',
                value: '$_totalHadir Hari',
              ),
              const SizedBox(height: 10),
              _buildMetricTile(
                icon: Icons.medical_services_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                label: 'Izin / Sakit',
                value: '$_totalIzinSakit Hari',
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _buildMetricTile(
                icon: Icons.access_time_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                label: 'Terlambat',
                value: '$_totalTerlambat Hari',
              ),
              const SizedBox(height: 10),
              _buildMetricTile(
                icon: Icons.pie_chart_outline_rounded,
                iconColor: kehadiranColor,
                iconBg: kehadiranColor.withValues(alpha: 0.1),
                label: 'Kehadiran',
                value: '$pctStr%',
                trailing: kehadiranLabel,
                trailingColor: kehadiranColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    String? trailing,
    Color? trailingColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: iconColor,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        trailing,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: trailingColor),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //   FILTER TABS
  // ══════════════════════════════════════════════════════════════
  Widget _buildFilterTabs() {
    final tabs = [
      _FilterTab('Semua ($_totalSemua)', 0),
      _FilterTab('Hadir ($_totalHadir)', 1),
      _FilterTab('Terlambat ($_totalTerlambat)', 2),
      _FilterTab('Izin/Sakit', 3),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isActive = _selectedFilterIndex == tab.index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = tab.index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF1D4ED8) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? const Color(0xFF1D4ED8) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //   SECTION TITLE (Catatan Harian)
  // ══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        Text(
          trailing,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //   KARTU CATATAN HARIAN
  // ══════════════════════════════════════════════════════════════
  Widget _buildDailyRecordCard(_DailyRecord record) {
    // Status badge
    Color badgeBg, badgeText;
    IconData badgeIcon;
    switch (record.category) {
      case 'hadir':
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF059669);
        badgeIcon = Icons.check_circle_rounded;
        break;
      case 'terlambat':
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFD97706);
        badgeIcon = Icons.access_time_filled_rounded;
        break;
      case 'izin_sakit':
        badgeBg = const Color(0xFFEFF6FF);
        badgeText = const Color(0xFF2563EB);
        badgeIcon = Icons.medical_services_rounded;
        break;
      default:
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFDC2626);
        badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header: Tanggal + Status Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      record.dayLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeText.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        record.status,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: badgeText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lokasi
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.location,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Jam Masuk & Jam Pulang (Row)
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeBlock(
                        label: 'Masuk',
                        time: record.checkInTime,
                        icon: Icons.login_rounded,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeBlock(
                        label: 'Pulang',
                        time: record.checkOutTime,
                        icon: Icons.logout_rounded,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Footer info badges: Face ID + Radius (hanya untuk hadir/terlambat)
                if (record.category == 'hadir' || record.category == 'terlambat')
                  Row(
                    children: [
                      if (record.faceIdValid)
                        _infoBadge(Icons.face_retouching_natural, 'Face ID Valid ✓', const Color(0xFF059669), const Color(0xFFECFDF5)),
                      const SizedBox(width: 8),
                      _infoBadge(Icons.gps_fixed_rounded, record.radiusInfo, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text('8 jam', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Dispensasi / Ekskul / Alasan Keterlambatan
                if (record.dispensasi != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          record.category == 'terlambat'
                              ? Icons.warning_amber_rounded
                              : Icons.event_note_rounded,
                          size: 16,
                          color: record.category == 'terlambat'
                              ? const Color(0xFFD97706)
                              : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.dispensasi!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Diagnosis & Attachment (untuk Izin/Sakit)
                if (record.diagnosis != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.diagnosis!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                              if (record.attachmentName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Surat dokter dari Klinik Sehat Sentosa telah tervalidasi oleh administrasi sekolah.',
                                  style: TextStyle(fontSize: 10.5, color: Colors.brown.shade600, height: 1.3),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (record.attachmentName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.attachmentName!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Lihat ▸',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: time,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
                    ),
                    TextSpan(
                      text: ' WIB',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //   BANNER SANGGAHAN
  // ══════════════════════════════════════════════════════════════
  Widget _buildSanggahanBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Text(
                'Data Presensi Kurang Sesuai?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Siswa berhak mengajukan sanggahan data kehadiran ke Guru BK atau Wali Kelas maks. 2×24 jam setelah tanggal tercatat.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309), height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: _showSanggahanDialog,
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 16),
              label: const Text(
                'Ajukan Sanggahan Sekarang ➔',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper class ───
class _FilterTab {
  final String label;
  final int index;
  const _FilterTab(this.label, this.index);
}
