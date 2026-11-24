import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/teacher/teacher_header_card.dart';
import '../widgets/teacher/teacher_statistics_card.dart';
import '../widgets/teacher/teacher_weekly_trend_card.dart';
import '../widgets/teacher/teacher_leave_verification_section.dart';
import '../widgets/teacher/teacher_unattended_student_section.dart';
import '../widgets/teacher/teacher_quick_actions_section.dart';

class TeacherHomeScreen extends StatefulWidget {
  final UserModel? userProfile;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchToStudentMode;

  const TeacherHomeScreen({
    super.key,
    required this.userProfile,
    required this.onSignOut,
    this.onSwitchToStudentMode,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedNavIndex = 0; // 0: Beranda, 1: Verifikasi, 2: Laporan, 3: Kelas
  String _selectedClass = 'XII RPL 1 (36 Siswa)';
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _unattendedKey = GlobalKey();

  void _scrollToUnattended() {
    // Scroll smoothly to Perhatian Khusus section
    if (_unattendedKey.currentContext != null) {
      Scrollable.ensureVisible(
        _unattendedKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent * 0.7,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showTeacherProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              widget.userProfile?.name.isNotEmpty == true
                  ? widget.userProfile!.name
                  : 'Drs. Bambang Sutrisno, M.Pd',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'NIP: 19780512 200312 1 002 • Guru Pembimbing & Piket',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFA7F3D0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Akun Guru & Operator Aktif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (widget.onSwitchToStudentMode != null) ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: const Color(0xFFEFF6FF),
                leading: const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFF1D4ED8)),
                title: const Text(
                  'Beralih ke Tampilan Siswa (Preview)',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                subtitle: const Text(
                  'Lihat dashboard dan fitur presensi dari sisi akun siswa.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onSwitchToStudentMode!();
                },
              ),
              const SizedBox(height: 10),
            ],

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: const Color(0xFFFEF2F2),
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              title: const Text(
                'Keluar dari Akun Guru',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                widget.onSignOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildCustomTeacherAppBar(),
      body: _buildTeacherBody(),
      bottomNavigationBar: _buildTeacherBottomBar(),
    );
  }

  PreferredSizeWidget _buildCustomTeacherAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, size: 20, color: Colors.white),
          ),
        ),
      ),
      leadingWidth: 52,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PresensiKu',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFA7F3D0), // Mint green
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Guru & Admin',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'SMK Negeri 1 Jakarta',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF334155),
                size: 23,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pemberitahuan: 3 permohonan izin siswa menunggu verifikasi Anda.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            Positioned(
              top: 13,
              right: 13,
              child: Container(
                width: 7.5,
                height: 7.5,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: _showTeacherProfileSheet,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 19),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherBody() {
    switch (_selectedNavIndex) {
      case 1:
        return _buildVerifikasiTab();
      case 2:
        return _buildLaporanTab();
      case 3:
        return _buildKelasTab();
      case 0:
      default:
        return _buildBerandaDashboard();
    }
  }

  Widget _buildBerandaDashboard() {
    final teacherGreetingName = widget.userProfile?.name.isNotEmpty == true
        ? widget.userProfile!.name
        : 'Pak Bambang';

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PANEL PRESENSI HARIAN (Blue Gradient Card)
          TeacherHeaderCard(
            teacherName: teacherGreetingName,
            selectedClass: _selectedClass,
            onClassChanged: (newClass) {
              setState(() {
                _selectedClass = newClass;
              });
            },
          ),
          const SizedBox(height: 18),

          // 2. STATISTIK HARI INI
          TeacherStatisticsCard(
            totalSiswa: 36,
            siswaHadir: 32,
            tepatWaktu: 28,
            terlambat: 4,
            izinCount: 2,
            sakitCount: 1,
            alpaCount: 1,
            onFollowUpAlpa: _scrollToUnattended,
          ),
          const SizedBox(height: 18),

          // 3. TREN KEHADIRAN MINGGUAN
          TeacherWeeklyTrendCard(
            className: _selectedClass.split(' (').first,
          ),
          const SizedBox(height: 18),

          // 4. VERIFIKASI IZIN & SAKIT
          TeacherLeaveVerificationSection(
            onViewAll: () {
              setState(() {
                _selectedNavIndex = 1; // Pindah ke tab Verifikasi
              });
            },
          ),
          const SizedBox(height: 18),

          // 5. PERHATIAN KHUSUS (BELUM PRESENSI)
          KeyedSubtree(
            key: _unattendedKey,
            child: TeacherUnattendedStudentSection(
              onRefresh: () {
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 18),

          // 6. AKSI & LAYANAN CEPAT
          const TeacherQuickActionsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVerifikasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TeacherLeaveVerificationSection(
            onViewAll: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan Kehadiran Kelas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rekapitulasi berkala kehadiran siswa kelas $_selectedClass',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TeacherWeeklyTrendCard(
            className: _selectedClass.split(' (').first,
          ),
          const SizedBox(height: 16),
          const TeacherQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildKelasTab() {
    final List<Map<String, String>> studentRoster = [
      {'name': 'Ahmad Rizky Pratama', 'nis': '222310104', 'status': 'Sakit'},
      {'name': 'Aulia Putri Maharani', 'nis': '222310105', 'status': 'Hadir (06:45)'},
      {'name': 'Bima Arya Pangestu', 'nis': '222310106', 'status': 'Alpa'},
      {'name': 'Citra Kirana', 'nis': '222310107', 'status': 'Hadir (06:50)'},
      {'name': 'Dimas Setiawan', 'nis': '222310109', 'status': 'Dispensasi'},
      {'name': 'Fajar Nugraha', 'nis': '222310110', 'status': 'Hadir (07:05)'},
      {'name': 'Gita Gutawa', 'nis': '222310111', 'status': 'Hadir (06:55)'},
      {'name': 'Hafiz Prasetyo', 'nis': '222310112', 'status': 'Terlambat (07:22)'},
      {'name': 'Siti Nurhaliza', 'nis': '222310108', 'status': 'Izin'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Siswa Kelas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$_selectedClass • Wali Kelas: Pak Bambang',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '36 Siswa',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...studentRoster.map((s) {
            Color statusBg = const Color(0xFFECFDF5);
            Color statusText = const Color(0xFF059669);

            if (s['status']!.contains('Alpa')) {
              statusBg = const Color(0xFFFEF2F2);
              statusText = const Color(0xFFDC2626);
            } else if (s['status']!.contains('Terlambat')) {
              statusBg = const Color(0xFFFFFBEB);
              statusText = const Color(0xFFD97706);
            } else if (s['status']!.contains('Izin') || s['status']!.contains('Sakit')) {
              statusBg = const Color(0xFFEFF6FF);
              statusText = const Color(0xFF2563EB);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        s['name']!.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
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
                          s['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'NIS: ${s['nis']}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s['status']!,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: statusText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTeacherBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1D4ED8),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.assignment_turned_in_rounded),
                Positioned(
                  top: -3,
                  right: -7,
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            label: 'Verifikasi',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Laporan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Kelas',
          ),
        ],
      ),
    );
  }
}

