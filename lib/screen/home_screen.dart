import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userProfile;
  bool _isLoading = true;
  bool _hasCheckedIn = false;
  bool _hasCheckedOut = false;
  String _checkInTime = '--:--';
  String _checkOutTime = '--:--';

  int _hadirCount = 0;
  int _terlambatCount = 0;
  int _izinSakitCount = 0;
  int _alpaCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      var profile = await _authService.getUserProfile(user.uid);
      if (profile == null) {
        // Beri jeda 1.5 detik jika proses set ke Firestore baru saja berjalan
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
    return minutesOfDay > deadlineMinutes ? 'Terlambat' : 'Hadir Tepat Waktu';
  }

  Future<void> _loadAttendanceSummary(String uid) async {
    final dateStr = _getTodayDateStr();
    final monthPrefix = _getCurrentMonthPrefix();

    bool checkedIn = false;
    bool checkedOut = false;
    String inTime = '--:--';
    String outTime = '--:--';

    int hadir = 0;
    int terlambat = 0;
    int izinSakit = 0;
    int alpa = 0;

    final Set<String> hadirDatesThisMonth = {};
    final Set<String> terlambatDatesThisMonth = {};

    try {
      final query = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: uid)
          .get();

      for (final doc in query.docs) {
        final data = doc.data();
        final docDate = (data['date'] as String?) ?? '';
        final type = (data['type'] as String?) ?? '';
        final status = ((data['status'] as String?) ?? '').toLowerCase();

        if (docDate == dateStr) {
          if (type == 'masuk') {
            checkedIn = true;
            inTime = (data['time'] as String?) ?? '07:15';
          } else if (type == 'pulang') {
            checkedOut = true;
            outTime = (data['time'] as String?) ?? '15:30';
          }
        }

        if (docDate.startsWith(monthPrefix)) {
          if (type == 'masuk') {
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

      hadir = hadirDatesThisMonth.length;
      terlambat = terlambatDatesThisMonth.length;

      if (mounted) {
        setState(() {
          _hasCheckedIn = checkedIn;
          _hasCheckedOut = checkedOut;
          _checkInTime = inTime;
          _checkOutTime = outTime;
          _hadirCount = hadir;
          _terlambatCount = terlambat;
          _izinSakitCount = izinSakit;
          _alpaCount = alpa;
        });
      }
    } catch (_) {}
  }

  Future<void> _recordAttendance(String type) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = _getTodayDateStr();
    final statusStr = type == 'masuk' ? _evaluateCheckInStatus(now) : 'Pulang Tercatat';

    final userName = (_userProfile?.name.isNotEmpty == true)
        ? _userProfile!.name
        : (user.displayName ?? 'Pengguna');
    final userRole = (_userProfile?.role.isNotEmpty == true)
        ? _userProfile!.role
        : 'siswa';
    final userNis = _userProfile?.nis ?? '';
    final userClassId = _userProfile?.classId ?? '';

    try {
      await _firestore.collection('attendance').add({
        'userId': user.uid,
        'userName': userName,
        'role': userRole,
        'nis': userNis,
        'classId': userClassId,
        'type': type,
        'date': dateStr,
        'time': timeStr,
        'timestamp': FieldValue.serverTimestamp(),
        'status': statusStr,
        'location': 'Radius 85m (Gerbang Utama Sekolah)',
      });

      await _loadAttendanceSummary(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type == 'masuk'
                        ? 'Presensi Masuk dicatat ($timeStr WIB • $statusStr)'
                        : 'Presensi Pulang dicatat ($timeStr WIB)',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Gagal mencatat presensi: $e'),
          ),
        );
      }
    }
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

  void _showSyncProfileDialog() {
    final user = _authService.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName ?? '');
    final nisController = TextEditingController();
    final classController =
        TextEditingController(text: 'XII MIPA 2 - Rekayasa Perangkat Lunak');
    final waController = TextEditingController();
    String selectedRole = 'siswa';
    bool isSyncing = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.sync_problem_rounded, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Simpan Data ke Firestore',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akun Firebase Auth Anda aktif, namun dokumen profil di Firestore belum ditemukan. Lengkapi data berikut untuk menyinkronkannya:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 12),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB91C1C),
                        height: 1.35,
                      ),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Peran Akun',
                    isDense: true,
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                    DropdownMenuItem(value: 'guru', child: Text('Guru & Staf')),
                  ],
                  onChanged: isSyncing
                      ? null
                      : (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
                        },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap *',
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nisController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Induk (NIS / NIP) *',
                    hintText: '210845',
                    isDense: true,
                    prefixIcon: Icon(Icons.numbers_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: classController,
                  decoration: const InputDecoration(
                    labelText: 'Kelas / Unit Kerja *',
                    isDense: true,
                    prefixIcon: Icon(Icons.class_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: waController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp (Opsional)',
                    hintText: '08123456789',
                    isDense: true,
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSyncing
                  ? null
                  : () {
                      nameController.dispose();
                      nisController.dispose();
                      classController.dispose();
                      waController.dispose();
                      Navigator.pop(dialogCtx);
                    },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSyncing
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final nis = nisController.text.trim();
                      final cls = classController.text.trim();

                      if (name.isEmpty || nis.isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Nama dan Nomor Induk wajib diisi!';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSyncing = true;
                        errorMessage = null;
                      });

                      try {
                        final newProfile = UserModel(
                          uid: user.uid,
                          email: user.email ?? '',
                          name: name,
                          role: selectedRole,
                          nis: nis,
                          classId: cls,
                          photoUrl: user.photoURL ?? '',
                          whatsapp: waController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        await _authService.saveUserProfile(newProfile);

                        nameController.dispose();
                        nisController.dispose();
                        classController.dispose();
                        waController.dispose();

                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        if (mounted) {
                          setState(() {
                            _userProfile = newProfile;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFF10B981),
                              content: Text('Berhasil menyimpan profil ke Firestore!'),
                            ),
                          );
                        }
                      } on FirebaseException catch (e) {
                        setDialogState(() {
                          isSyncing = false;
                          errorMessage =
                              'Gagal menulis ke Firestore: [${e.code}] ${e.message}\n\n'
                              'Periksa Firestore Database dan Security Rules di Firebase Console.';
                        });
                      } catch (e) {
                        setDialogState(() {
                          isSyncing = false;
                          errorMessage = 'Error: $e';
                        });
                      }
                    },
              child: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan ke Firestore',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
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

    final user = _authService.currentUser;
    final displayName = (_userProfile?.name.isNotEmpty == true)
        ? _userProfile!.name
        : (user?.displayName ?? 'Pengguna PresensiKu');
    final isGuru = _userProfile?.role.toLowerCase() == 'guru' ||
        _userProfile?.role.toLowerCase() == 'teacher';
    final roleLabel = isGuru ? 'Guru & Staf' : 'Siswa';
    final idNumber = (_userProfile?.nis.isNotEmpty == true) ? _userProfile!.nis : '-';
    final classInfo = (_userProfile?.classId.isNotEmpty == true)
        ? _userProfile!.classId
        : 'Kelas / Unit Terdaftar';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.co_present, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'PresensiKu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Keluar',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_userProfile == null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Profil Belum Tersimpan di Firestore',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Akun Firebase Auth aktif, namun dokumen profil di koleksi users belum ditemukan. Sinkronkan data profil Anda sekarang.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D), height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showSyncProfileDialog,
                        icon: const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.white),
                        label: const Text(
                          'Simpan Profil ke Firestore Sekarang',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // User Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No. Induk: $idNumber',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    classInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Radius Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.my_location_rounded, color: Color(0xFF059669), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dalam Radius Sekolah (85m)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          'Presensi digital diizinkan dan geolokasi valid.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Section
            const Text(
              'Catat Presensi Hari Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Masuk
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Presensi Masuk',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Icon(
                              _hasCheckedIn ? Icons.check_circle : Icons.schedule,
                              size: 18,
                              color: _hasCheckedIn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hasCheckedIn ? 'Pukul $_checkInTime WIB' : 'Batas 07:15 WIB',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasCheckedIn
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                            fontWeight: _hasCheckedIn ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasCheckedIn
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF1D4ED8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _hasCheckedIn ? null : () => _recordAttendance('masuk'),
                            child: Text(
                              _hasCheckedIn ? 'Sudah Masuk' : 'Absen Masuk',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _hasCheckedIn ? const Color(0xFF94A3B8) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Pulang
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Presensi Pulang',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Icon(
                              _hasCheckedOut ? Icons.check_circle : Icons.schedule,
                              size: 18,
                              color: _hasCheckedOut
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hasCheckedOut ? 'Pukul $_checkOutTime WIB' : 'Mulai 15:00 WIB',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasCheckedOut
                                ? const Color(0xFF10B981)
                                : const Color(0xFF64748B),
                            fontWeight: _hasCheckedOut ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasCheckedOut
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF0284C7),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _hasCheckedOut ? null : () => _recordAttendance('pulang'),
                            child: Text(
                              _hasCheckedOut ? 'Sudah Pulang' : 'Absen Pulang',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _hasCheckedOut ? const Color(0xFF94A3B8) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Attendance Statistics
            const Text(
              'Statistik Kehadiran Bulan Ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatItem('Hadir', '$_hadirCount', const Color(0xFF10B981)),
                const SizedBox(width: 10),
                _buildStatItem('Terlambat', '$_terlambatCount', const Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                _buildStatItem('Izin/Sakit', '$_izinSakitCount', const Color(0xFF3B82F6)),
                const SizedBox(width: 10),
                _buildStatItem('Alpa', '$_alpaCount', const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 24),

            // Live Attendance Stream from Firestore
            const Text(
              'Riwayat Presensi Terbaru',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('attendance')
                  .where('userId', isEqualTo: user?.uid ?? '')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_note_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada rekaman presensi.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMasuk = data['type'] == 'masuk';
                    final typeLabel = isMasuk ? 'Presensi Masuk' : 'Presensi Pulang';
                    final date = (data['date'] as String?) ?? '';
                    final time = (data['time'] as String?) ?? '';
                    final location = (data['location'] as String?) ?? 'Radius Valid';
                    final status = (data['status'] as String?) ?? '';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isMasuk
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isMasuk ? Icons.login_rounded : Icons.logout_rounded,
                              size: 18,
                              color: isMasuk
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.isNotEmpty ? '$typeLabel • $status' : typeLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$date • $location',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$time WIB',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}