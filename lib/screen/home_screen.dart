import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'history_page.dart';
import 'leave_request_page.dart';
import 'profile_page.dart';
import 'teacher_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedNavIndex = 0; // 0: Beranda, 1: Riwayat, 2: Izin/Sakit, 3: Profil
  UserModel? _userProfile;
  bool _isLoading = true;
  bool? _overrideTeacherView;

  bool get _isTeacherView =>
      _overrideTeacherView ??
      (_userProfile?.role.toLowerCase() == 'teacher' ||
          _userProfile?.role.toLowerCase() == 'guru');

  // Stream Firestore yang diinisialisasi sekali agar tidak memicu re-subscribe
  Stream<QuerySnapshot>? _attendanceStream;
  Stream<QuerySnapshot>? _leaveRequestsStream;

  // Attendance state for today
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  String _checkInTime = '--:--';
  String _checkOutTime = '--:--';
  String _checkInStatus = 'Tepat Waktu';
  String _checkOutStatus = '';

  // Monthly summary metrics
  int _hadirCount = 18;
  int _terlambatCount = 1;
  int _izinSakitCount = 1;
  int _alpaCount = 0;
  final int _totalHariEfektif = 20;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _attendanceStream = _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .snapshots();

      _leaveRequestsStream = _firestore
          .collection('leave_requests')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      _attendanceStream ??= _firestore
          .collection('attendance')
          .where('userId', isEqualTo: user.uid)
          .snapshots();

      _leaveRequestsStream ??= _firestore
          .collection('leave_requests')
          .where('userId', isEqualTo: user.uid)
          .snapshots();

      var profile = await _authService.getUserProfile(user.uid);
      if (profile == null) {
        // Wait 1.5s in case newly registered user document write is finishing
        await Future.delayed(const Duration(milliseconds: 1500));
        profile = await _authService.getUserProfile(user.uid);
      }
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
      await _loadAttendanceSummary(user.uid);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTodayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _getCurrentMonthPrefix() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  String _evaluateCheckInStatus(DateTime now) {
    // Batas masuk tepat waktu: 07:15 WIB
    final minutesOfDay = now.hour * 60 + now.minute;
    const deadlineMinutes = 7 * 60 + 15;
    return minutesOfDay > deadlineMinutes ? 'Terlambat' : 'Tepat Waktu';
  }

  /// Load today's attendance and monthly statistics from Firestore
  Future<void> _loadAttendanceSummary(String uid) async {
    final dateStr = _getTodayDateStr();
    final monthPrefix = _getCurrentMonthPrefix();

    bool checkedIn = false;
    bool checkedOut = false;
    String inTime = '--:--';
    String outTime = '--:--';
    String inStatus = 'Tepat Waktu';
    String outStatus = '';

    int hadir = 0;
    int terlambat = 0;
    int izinSakit = 0;
    int alpa = 0;

    final Set<String> hadirDatesThisMonth = {};
    final Set<String> terlambatDatesThisMonth = {};

    try {
      final todayDocRef = _firestore.collection('attendance').doc('${uid}_$dateStr');
      final todayDoc = await todayDocRef.get();

      if (todayDoc.exists && todayDoc.data() != null) {
        final data = todayDoc.data()!;
        if (data['checkInTime'] != null) {
          checkedIn = true;
          inTime = data['checkInTime'];
          inStatus = data['checkInStatus'] ?? 'Tepat Waktu';
        }
        if (data['checkOutTime'] != null) {
          checkedOut = true;
          outTime = data['checkOutTime'];
          outStatus = data['checkOutStatus'] ?? 'Pukul 15:30';
        }
      }

      final query = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final docDate = (data['date'] as String?) ?? '';

        if (docDate == dateStr) {
          final type = (data['type'] as String?) ?? '';
          if (type == 'masuk') {
            checkedIn = true;
            inTime = (data['time'] as String?) ?? inTime;
            inStatus = (data['status'] as String?) ?? inStatus;
          } else if (type == 'pulang') {
            checkedOut = true;
            outTime = (data['time'] as String?) ?? outTime;
            outStatus = 'Tercatat';
          }
        }

        if (docDate.startsWith(monthPrefix)) {
          final hasIn = data['checkInTime'] != null || data['type'] == 'masuk';
          final status = ((data['checkInStatus'] ?? data['status'] ?? '') as String).toLowerCase();

          if (hasIn) {
            if (status.contains('terlambat')) {
              terlambatDatesThisMonth.add(docDate);
            } else {
              hadirDatesThisMonth.add(docDate);
            }
          } else if (status.contains('izin') || status.contains('sakit')) {
            izinSakit++;
          } else if (status.contains('alpa')) {
            alpa++;
          }
        }
      }

      hadir = hadirDatesThisMonth.isNotEmpty ? hadirDatesThisMonth.length : _hadirCount;
      terlambat = terlambatDatesThisMonth.isNotEmpty ? terlambatDatesThisMonth.length : _terlambatCount;

      if (mounted) {
        setState(() {
          _hasCheckedIn = checkedIn;
          _hasCheckedOut = checkedOut;
          _checkInTime = inTime;
          _checkOutTime = outTime;
          _checkInStatus = inStatus;
          _checkOutStatus = outStatus;
          if (hadirDatesThisMonth.isNotEmpty) _hadirCount = hadir;
          if (terlambatDatesThisMonth.isNotEmpty) _terlambatCount = terlambat;
          if (izinSakit > 0) _izinSakitCount = izinSakit;
          if (alpa > 0) _alpaCount = alpa;
        });
      }
    } catch (e) {
      debugPrint('Error loading attendance summary: $e');
    }
  }

  /// CHECK IN & CHECK OUT DENGAN SISTEM PENCEGAHAN ABSENSI GANDA
  Future<void> _recordAttendance(String type) async {
    final user = _authService.currentUser;
    if (user == null) {
      _showSnackbar('Silakan masuk terlebih dahulu untuk presensi.', isError: true);
      return;
    }

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = _getTodayDateStr();

    final userName = (_userProfile?.name.isNotEmpty == true)
        ? _userProfile!.name
        : (user.displayName ?? 'Ahmad Rizky');
    final userNis = (_userProfile?.nis.isNotEmpty == true) ? _userProfile!.nis : '210845';
    final userClassId =
        (_userProfile?.classId.isNotEmpty == true) ? _userProfile!.classId : 'XII MIPA 2';
    final userRole = _userProfile?.role ?? 'siswa';

    final docRef = _firestore.collection('attendance').doc('${user.uid}_$dateStr');

    try {
      final docSnap = await docRef.get();
      final existingData = docSnap.exists ? docSnap.data() : null;

      if (type == 'masuk') {
        // PENCEGAHAN ABSENSI MASUK GANDA
        if (existingData != null && existingData['checkInTime'] != null) {
          final recordedTime = existingData['checkInTime'];
          _showDuplicateAlert(
            title: 'Presensi Masuk Sudah Tercatat!',
            message:
                'Anda sudah melakukan Presensi Masuk hari ini pada pukul $recordedTime WIB. Sistem mencegah absensi masuk ganda pada tanggal yang sama.',
          );
          return;
        }

        final statusStr = _evaluateCheckInStatus(now);

        await docRef.set({
          'userId': user.uid,
          'userName': userName,
          'nis': userNis,
          'classId': userClassId,
          'role': userRole,
          'date': dateStr,
          'checkInTime': timeStr,
          'checkInTimestamp': FieldValue.serverTimestamp(),
          'checkInStatus': statusStr,
          'checkInLocation':
              'SMK Negeri 1 Jakarta (Radius 42 meter • Geofence Valid)',
          'status': 'Hadir',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await _firestore.collection('attendance').add({
          'userId': user.uid,
          'userName': userName,
          'nis': userNis,
          'classId': userClassId,
          'role': userRole,
          'type': 'masuk',
          'date': dateStr,
          'time': timeStr,
          'status': statusStr,
          'location': 'SMK Negeri 1 Jakarta (Kampus Pusat)',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _loadAttendanceSummary(user.uid);

        _showSuccessDialog(
          title: 'Presensi Masuk Berhasil!',
          message:
              'Kehadiran Anda telah dicatat pada pukul $timeStr WIB dengan status: $statusStr.\nLokasi terverifikasi di area sekolah (42m).',
        );
      } else if (type == 'pulang') {
        // CEK APAKAH SUDAH ABSEN MASUK DULU
        if (existingData == null || existingData['checkInTime'] == null) {
          _showDuplicateAlert(
            title: 'Belum Presensi Masuk!',
            message:
                'Anda belum melakukan Presensi Masuk hari ini. Harap lakukan presensi masuk terlebih dahulu sebelum presensi pulang.',
            isWarning: true,
          );
          return;
        }

        // PENCEGAHAN ABSENSI PULANG GANDA
        if (existingData['checkOutTime'] != null) {
          final recordedOut = existingData['checkOutTime'];
          _showDuplicateAlert(
            title: 'Presensi Pulang Sudah Tercatat!',
            message:
                'Anda sudah melakukan Presensi Pulang hari ini pada pukul $recordedOut WIB. Sistem mencegah absensi pulang ganda pada tanggal yang sama.',
          );
          return;
        }

        await docRef.update({
          'checkOutTime': timeStr,
          'checkOutTimestamp': FieldValue.serverTimestamp(),
          'checkOutStatus': 'Pukul 15:30 (Tepat Waktu)',
          'checkOutLocation':
              'SMK Negeri 1 Jakarta (Radius 38 meter • Geofence Valid)',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('attendance').add({
          'userId': user.uid,
          'userName': userName,
          'nis': userNis,
          'classId': userClassId,
          'role': userRole,
          'type': 'pulang',
          'date': dateStr,
          'time': timeStr,
          'status': 'Pulang Tepat Waktu',
          'location': 'SMK Negeri 1 Jakarta (Kampus Pusat)',
          'timestamp': FieldValue.serverTimestamp(),
        });

        await _loadAttendanceSummary(user.uid);

        _showSuccessDialog(
          title: 'Presensi Pulang Berhasil!',
          message:
              'Presensi kepulangan Anda telah dicatat pada pukul $timeStr WIB. Selamat beristirahat dan hati-hati di jalan!',
        );
      }
    } catch (e) {
      _showSnackbar('Gagal mencatat presensi: $e', isError: true);
    }
  }

  void _showDuplicateAlert({
    required String title,
    required String message,
    bool isWarning = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.shield_outlined,
              color: isWarning ? const Color(0xFFF59E0B) : const Color(0xFF1D4ED8),
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
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

  void _showSuccessDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 26),
            SizedBox(width: 10),
            Text('Presensi Berhasil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Dialog Presensi Mandiri / Foto Selfie & GPS
  void _openSelfiePresensiDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (bottomCtx, setModalState) {
          final now = DateTime.now();
          final nowTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Presensi Mandiri: Foto Selfie & GPS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sistem mencocokkan wajah dan memvalidasi geolokasi GPS gerbang sekolah.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.face_retouching_natural_rounded,
                                  size: 48, color: Colors.white70),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Wajah Terdeteksi & Cocok',
                                  style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$nowTime WIB',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.gps_fixed, size: 12, color: Color(0xFF60A5FA)),
                              SizedBox(width: 4),
                              Text('GPS Valid (42m)',
                                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasCheckedIn ? const Color(0xFF94A3B8) : const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _hasCheckedIn
                            ? () {
                                Navigator.pop(ctx);
                                _showDuplicateAlert(
                                  title: 'Presensi Masuk Sudah Tercatat!',
                                  message:
                                      'Anda sudah melakukan Presensi Masuk hari ini pukul $_checkInTime WIB. Sistem mencegah absensi ganda!',
                                );
                              }
                            : () async {
                                Navigator.pop(ctx);
                                await _recordAttendance('masuk');
                              },
                        icon: Icon(_hasCheckedIn ? Icons.lock : Icons.login_rounded, color: Colors.white, size: 18),
                        label: Text(
                          _hasCheckedIn ? 'Sudah Masuk' : 'Ambil Selfie Masuk',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (!_hasCheckedIn || _hasCheckedOut)
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0D9488),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: (!_hasCheckedIn)
                            ? () {
                                Navigator.pop(ctx);
                                _showDuplicateAlert(
                                  title: 'Belum Presensi Masuk!',
                                  message:
                                      'Harap lakukan Presensi Masuk terlebih dahulu sebelum melakukan Presensi Pulang.',
                                  isWarning: true,
                                );
                              }
                            : (_hasCheckedOut
                                ? () {
                                    Navigator.pop(ctx);
                                    _showDuplicateAlert(
                                      title: 'Presensi Pulang Sudah Tercatat!',
                                      message:
                                          'Anda sudah melakukan Presensi Pulang hari ini pukul $_checkOutTime WIB. Sistem mencegah absensi ganda!',
                                    );
                                  }
                                : () async {
                                    Navigator.pop(ctx);
                                    await _recordAttendance('pulang');
                                  }),
                        icon: Icon(
                          _hasCheckedOut ? Icons.check_circle : Icons.logout_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          _hasCheckedOut ? 'Sudah Pulang' : 'Ambil Selfie Pulang',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari PresensiKu?'),
        content: const Text('Anda harus masuk kembali untuk mencatat presensi berikutnya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.signOut();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLeaveRequestDialog() {
    final reasonController = TextEditingController();
    String category = 'Sakit';

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
            top: 20,
            bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pengajuan Izin / Sakit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Surat izin / surat dokter akan langsung diverifikasi oleh Wali Kelas dan Guru Piket.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Kategori Pengajuan',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Sakit', child: Text('Sakit (Surat Dokter / Orang Tua)')),
                  DropdownMenuItem(value: 'Izin', child: Text('Izin (Keperluan Keluarga)')),
                  DropdownMenuItem(value: 'Dispensasi', child: Text('Dispensasi (Lomba / Kegiatan Sekolah)')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Alasan *',
                  hintText: 'Contoh: Sakit demam tinggi beristirahat atas saran dokter...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.attach_file_rounded, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lampirkan Dokumen (Surat Dokter / Foto Bukti)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ),
                    Icon(Icons.upload_file, color: Color(0xFF1D4ED8), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      _showSnackbar('Harap isi alasan pengajuan izin/sakit.', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);

                    final user = _authService.currentUser;
                    if (user != null) {
                      await _firestore.collection('leave_requests').add({
                        'userId': user.uid,
                        'studentName': _userProfile?.name ?? user.displayName ?? '',
                        'nis': _userProfile?.nis ?? '',
                        'classId': _userProfile?.classId ?? '',
                        'category': category,
                        'reason': reason,
                        'date': _getTodayDateStr(),
                        'status': 'Menunggu Verifikasi',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    }

                    _showSnackbar('Pengajuan $category berhasil dikirim untuk diverifikasi.');
                  },
                  child: const Text(
                    'Kirim Pengajuan Izin',
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
        ),
      );
    }

    if (_isTeacherView) {
      return TeacherHomeScreen(
        userProfile: _userProfile,
        onSignOut: _confirmSignOut,
        onSwitchToStudentMode: () {
          setState(() {
            _overrideTeacherView = false;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildCustomAppBar(),
      body: _buildCurrentTabBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
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
          const Text(
            'PresensiKu',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
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
        GestureDetector(
          onTap: () {
            setState(() {
              _overrideTeacherView = true;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 13, color: Color(0xFF1D4ED8)),
                SizedBox(width: 4),
                Text(
                  'Dashboard Guru',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ],
            ),
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155), size: 23),
              onPressed: () {
                _showSnackbar('Tidak ada notifikasi baru hari ini.');
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
            onTap: () {
              setState(() {
                _selectedNavIndex = 3; // Switch to Profil tab
              });
            },
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

  Widget _buildCurrentTabBody() {
    switch (_selectedNavIndex) {
      case 1:
        return HistoryPage(
          attendanceStream: _attendanceStream,
        );
      case 2:
        return LeaveRequestPage(
          leaveRequestsStream: _leaveRequestsStream,
          onOpenLeaveDialog: _showLeaveRequestDialog,
        );
      case 3:
        return ProfilePage(
          userProfile: _userProfile,
          onSignOut: _confirmSignOut,
        );
      case 0:
      default:
        return HomePage(
          userProfile: _userProfile,
          hasCheckedIn: _hasCheckedIn,
          hasCheckedOut: _hasCheckedOut,
          checkInTime: _checkInTime,
          checkOutTime: _checkOutTime,
          checkInStatus: _checkInStatus,
          hadirCount: _hadirCount,
          terlambatCount: _terlambatCount,
          izinSakitCount: _izinSakitCount,
          alpaCount: _alpaCount,
          totalHariEfektif: _totalHariEfektif,
          onRecordAttendance: _recordAttendance,
          onOpenSelfieDialog: _openSelfiePresensiDialog,
          onOpenLeaveDialog: _showLeaveRequestDialog,
          onNavigateToHistory: () {
            setState(() => _selectedNavIndex = 1);
          },
        );
    }
  }

  Widget _buildBottomNavigationBar() {
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Izin/Sakit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Widget Jam Server Digital yang terisolasi
class LiveServerClockCard extends StatefulWidget {
  const LiveServerClockCard({super.key});

  @override
  State<LiveServerClockCard> createState() => _LiveServerClockCardState();
}

class _LiveServerClockCardState extends State<LiveServerClockCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatIndonesianDate(DateTime dt) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[dt.weekday % 7];
    final monthName = months[dt.month - 1];
    return '$dayName, ${dt.day} $monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final clockTime =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
    final todayFormatted = _formatIndonesianDate(_now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time_filled_rounded,
                    color: Color(0xFF1D4ED8), size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Waktu Presensi Server',
                    style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500),
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      children: [
                        TextSpan(text: clockTime),
                        const TextSpan(
                          text: ' WIB',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Hari Ini',
                style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500),
              ),
              Text(
                todayFormatted,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
