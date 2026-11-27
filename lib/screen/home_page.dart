import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart'; // For LiveServerClockCard

class _ClassScheduleItemData {
  final String timeRange;
  final int startMinutes;
  final int endMinutes;
  final String subject;
  final String sessionBadge;
  final String room;
  final String teacher;

  const _ClassScheduleItemData({
    required this.timeRange,
    required this.startMinutes,
    required this.endMinutes,
    required this.subject,
    required this.sessionBadge,
    required this.room,
    required this.teacher,
  });

  factory _ClassScheduleItemData.fromMap(Map<String, dynamic> data) {
    return _ClassScheduleItemData(
      timeRange: (data['timeRange'] as String?) ?? '--:--\ns/d\n--:--',
      startMinutes: (data['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (data['endMinutes'] as num?)?.toInt() ?? 0,
      subject: (data['subject'] as String?) ?? 'Mata Pelajaran',
      sessionBadge: (data['sessionBadge'] as String?) ?? 'Sesi',
      room: (data['room'] as String?) ?? '-',
      teacher: (data['teacher'] as String?) ?? '-',
    );
  }
}

class HomePage extends StatelessWidget {
  final UserModel? userProfile;
  final bool hasCheckedIn;
  final bool hasCheckedOut;
  final String checkInTime;
  final String checkOutTime;
  final String checkInStatus;
  final int hadirCount;
  final int terlambatCount;
  final int izinSakitCount;
  final int alpaCount;
  final int totalHariEfektif;
  final int? currentDistanceMeters;
  final bool isWithinRadius;
  final String? currentLocationName;
  final Stream<QuerySnapshot>? schedulesStream;
  final Function(String type) onRecordAttendance;
  final VoidCallback onOpenLeaveDialog;
  final VoidCallback onNavigateToHistory;

  const HomePage({
    super.key,
    required this.userProfile,
    required this.hasCheckedIn,
    required this.hasCheckedOut,
    required this.checkInTime,
    required this.checkOutTime,
    required this.checkInStatus,
    required this.hadirCount,
    required this.terlambatCount,
    required this.izinSakitCount,
    required this.alpaCount,
    required this.totalHariEfektif,
    this.currentDistanceMeters,
    this.isWithinRadius = true,
    this.currentLocationName,
    required this.schedulesStream,
    required this.onRecordAttendance,
    required this.onOpenLeaveDialog,
    required this.onNavigateToHistory,
  });

  String _formatIndonesianMonth(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[dt.month - 1];
  }

  String _formatIndonesianDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
      default:
        return 'Minggu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (userProfile?.name.isNotEmpty == true)
        ? userProfile!.name
        : 'Ahmad Rizky Pratama';
    final nisNumber = (userProfile?.nis.isNotEmpty == true)
        ? userProfile!.nis
        : '210845';
    final classInfo = (userProfile?.classId.isNotEmpty == true)
        ? userProfile!.classId
        : 'XII MIPA 2';
    final monthName = _formatIndonesianMonth(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GREETING & IDENTITAS SISWA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Halo, $displayName 👋',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIS: $nisNumber • Kelas: $classInfo',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 12, color: Color(0xFF059669)),
                    SizedBox(width: 4),
                    Text(
                      'Siswa Aktif',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2. LIVE SERVER CLOCK & TANGGAL CARD (Widget terisolasi)
          const LiveServerClockCard(),
          const SizedBox(height: 16),

          // 3. STATUS ABSENSI HARI INI CARD (CHECK IN & CHECK OUT)
          _buildTodayAttendanceCard(context),
          const SizedBox(height: 18),

          // 4. STATISTIK KEHADIRAN BULAN INI
          _buildMonthlyStatisticsCard(monthName),
          const SizedBox(height: 18),

          // 5. JADWAL KELAS HARI INI
          _buildTodayClassScheduleCard(),
          const SizedBox(height: 18),

          // 6. LAYANAN & AKSI CEPAT
          _buildQuickServicesSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceCard(BuildContext context) {
    final hasBothChecked = hasCheckedIn && hasCheckedOut;
    final statusHeader = hasBothChecked
        ? 'PRESENSI LENGKAP HARI INI'
        : (hasCheckedIn
              ? 'PRESENSI MASUK TERCATAT'
              : 'BELUM PRESENSI HARI INI');

    final locationText = (currentLocationName?.isNotEmpty == true)
        ? currentLocationName!
        : 'SMK Negeri 1 Jakarta (Kampus Pusat)';
    final radiusLabel = currentDistanceMeters != null
        ? 'Radius: $currentDistanceMeters meter'
        : 'Radius belum terdeteksi';
    final statusGeofenceLabel = currentDistanceMeters == null
        ? 'Menunggu GPS'
        : (isWithinRadius
              ? 'Di dalam area geofence valid ✓'
              : 'Di luar area geofence');

    final isOutside = !isWithinRadius && currentDistanceMeters != null;
    final bannerBg =
        isOutside ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final bannerBorder =
        isOutside ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0);
    final accentColor =
        isOutside ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final titleColor =
        isOutside ? const Color(0xFF991B1B) : const Color(0xFF065F46);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: hasCheckedIn
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusHeader,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Sesi Pagi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Geofence Banner (Dinamis dari GPS)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bannerBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        '$radiusLabel • $statusGeofenceLabel',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isOutside
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline,
                  color: accentColor,
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dual Column (Masuk & Pulang)
          Row(
            children: [
              // Jam Masuk
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jam Masuk',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: hasCheckedIn
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasCheckedIn ? checkInStatus : 'Batas 07:15',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: hasCheckedIn
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(text: checkInTime),
                            if (hasCheckedIn)
                              const TextSpan(
                                text: ' WIB',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            hasCheckedIn
                                ? Icons.verified
                                : Icons.schedule_outlined,
                            size: 12,
                            color: hasCheckedIn
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hasCheckedIn
                                  ? 'Terverifikasi GPS'
                                  : 'Belum Absen',
                              style: TextStyle(
                                fontSize: 10,
                                color: hasCheckedIn
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasCheckedIn
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF1D4ED8),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => onRecordAttendance('masuk'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasCheckedIn
                                    ? Icons.lock_outline
                                    : Icons.login_rounded,
                                size: 14,
                                color: hasCheckedIn
                                    ? const Color(0xFF64748B)
                                    : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                hasCheckedIn
                                    ? 'Terkunci Aman'
                                    : 'Presensi Masuk',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: hasCheckedIn
                                      ? const Color(0xFF64748B)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Jam Pulang
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jam Pulang',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: hasCheckedOut
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              hasCheckedOut ? 'Tercatat' : 'Pukul 15:30',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: hasCheckedOut
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          children: [
                            TextSpan(text: checkOutTime),
                            if (hasCheckedOut)
                              const TextSpan(
                                text: ' WIB',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            hasCheckedOut ? Icons.check_circle : Icons.schedule,
                            size: 12,
                            color: hasCheckedOut
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hasCheckedOut
                                  ? 'Pulang Selesai'
                                  : 'Buka 15:00 WIB',
                              style: TextStyle(
                                fontSize: 10,
                                color: hasCheckedOut
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasCheckedOut
                                ? const Color(0xFFE2E8F0)
                                : (!hasCheckedIn
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF1D4ED8)),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => onRecordAttendance('pulang'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasCheckedOut
                                    ? Icons.check_circle_outline
                                    : (!hasCheckedIn
                                          ? Icons.block
                                          : Icons.logout_rounded),
                                size: 14,
                                color: (hasCheckedOut || !hasCheckedIn)
                                    ? const Color(0xFF64748B)
                                    : Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                hasCheckedOut
                                    ? 'Selesai'
                                    : (!hasCheckedIn
                                          ? 'Belum Masuk'
                                          : 'Presensi Pulang'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: (hasCheckedOut || !hasCheckedIn)
                                      ? const Color(0xFF64748B)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatisticsCard(String monthName) {
    final effectiveDenominator = totalHariEfektif > 0 ? totalHariEfektif : 20;
    final totalAttendedDays = hadirCount + terlambatCount;
    final attendanceRatio = (totalAttendedDays / effectiveDenominator).clamp(
      0.0,
      1.0,
    );
    final attendancePercent = (attendanceRatio * 100).round();
    final isMeetingTarget = attendancePercent >= 85;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.pie_chart_outline_rounded,
                    size: 19,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statistik Bulan $monthName',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Text(
                  'Total $totalHariEfektif Hari Efektif',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 STATISTICAL METRICS GRID
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.check,
                  iconBg: const Color(0xFF34D399),
                  label: 'Hadir',
                  value: '$hadirCount Hari',
                  subtext: '$attendancePercent% Rasio',
                  cardBg: const Color(0xFFF0FDF4),
                  borderCol: const Color(0xFFBBF7D0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFFBBF24),
                  label: 'Terlambat',
                  value: '$terlambatCount Hari',
                  subtext: 'Batas masuk 07:15',
                  cardBg: const Color(0xFFFFFBEB),
                  borderCol: const Color(0xFFFDE68A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.calendar_today_rounded,
                  iconBg: const Color(0xFF818CF8),
                  label: 'Izin / Sakit',
                  value: '$izinSakitCount Hari',
                  subtext: 'Pengajuan Tercatat',
                  cardBg: const Color(0xFFEEF2FF),
                  borderCol: const Color(0xFFC7D2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.close_rounded,
                  iconBg: const Color(0xFFF87171),
                  label: 'Tanpa Keterangan',
                  value: '$alpaCount Hari',
                  subtext: alpaCount == 0
                      ? 'Disiplin Prima'
                      : 'Perlu Konfirmasi',
                  cardBg: const Color(0xFFFEF2F2),
                  borderCol: const Color(0xFFFECACA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Target
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Target Kehadiran Semester Ini',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '$attendancePercent% (Target Min. 85%)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: attendanceRatio,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMeetingTarget
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '0%',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      isMeetingTarget
                          ? '✓ Melampaui Standar Kelulusan'
                          : '• Dalam Pemantauan Target',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isMeetingTarget
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    const Text(
                      '100%',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
    required String subtext,
    required Color cardBg,
    required Color borderCol,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayClassScheduleCard() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final dayLabel = _formatIndonesianDay(now.weekday);

    return StreamBuilder<QuerySnapshot>(
      stream: schedulesStream,
      builder: (context, snapshot) {
        List<_ClassScheduleItemData> schedules = const [];
        int countLabel = 0;

        if (snapshot.hasData) {
          final filtered =
              snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((_) => true)
                  .map(_ClassScheduleItemData.fromMap)
                  .toList()
                ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

          schedules = filtered;
          countLabel = schedules.length;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 19,
                        color: Color(0xFF1D4ED8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jadwal Kelas ($dayLabel)',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$countLabel Mata Pelajaran',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: const Text(
                    'Gagal memuat jadwal kelas dari database.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else if (schedules.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Belum ada jadwal kelas tersimpan di database untuk hari ini.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                for (int i = 0; i < schedules.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final item = schedules[i];
                      final isOngoing =
                          currentMinutes >= item.startMinutes &&
                          currentMinutes <= item.endMinutes;

                      return _buildScheduleItem(
                        timeRange: item.timeRange,
                        subject: item.subject,
                        sessionBadge: item.sessionBadge,
                        room: item.room,
                        teacher: item.teacher,
                        isOngoing: isOngoing,
                      );
                    },
                  ),
                  if (i < schedules.length - 1) const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleItem({
    required String timeRange,
    required String subject,
    required String sessionBadge,
    required String room,
    required String teacher,
    bool isOngoing = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOngoing ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
          width: isOngoing ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isOngoing
                  ? const Color(0xFFDBEAFE)
                  : const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              timeRange,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isOngoing
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF475569),
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sessionBadge,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  room,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        teacher,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layanan & Aksi Cepat',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.assignment_outlined,
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF1D4ED8),
                title: 'Izin / Sakit',
                subtext: 'Upload Dok',
                onTap: onOpenLeaveDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.history_rounded,
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                title: 'Riwayat Absen',
                subtext: 'Log Lengkap',
                onTap: onNavigateToHistory,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.description_outlined,
                iconBg: const Color(0xFFE0E7FF),
                iconColor: const Color(0xFF4F46E5),
                title: 'Rekap Nilai',
                subtext: 'Unduh PDF',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Mempersiapkan Rekap Nilai Akademik semester berjalan...',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtext,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}