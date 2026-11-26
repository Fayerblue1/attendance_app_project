import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
// import '../widgets/google_logo.dart';

class RegisterView extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterView({super.key, required this.onSwitchToLogin});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthService _authService = AuthService();

  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'siswa'; // 'siswa' or 'guru'
  String _selectedClass = 'XII MIPA 2 - Rekayasa Perangkat Lunak';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final List<String> _studentClasses = [
    'XII MIPA 2 - Rekayasa Perangkat Lunak',
    'XII MIPA 1 - Rekayasa Perangkat Lunak',
    'XI RPL 1 - Rekayasa Perangkat Lunak',
    'XI RPL 2 - Rekayasa Perangkat Lunak',
    'X PPLG 1 - Rekayasa Perangkat Lunak & Gim',
    'X PPLG 2 - Rekayasa Perangkat Lunak & Gim',
    'XII TKJ 1 - Teknik Komputer & Jaringan',
    'XI TKJ 1 - Teknik Komputer & Jaringan',
    'XII MM 1 - Desain Komunikasi Visual',
    'XII OTKP 1 - Manajemen Perkantoran',
    'XII AKL 1 - Akuntansi & Keuangan',
  ];

  final List<String> _teacherRoles = [
    'Guru Produktif - Rekayasa Perangkat Lunak',
    'Guru Matematika',
    'Guru Bahasa Indonesia',
    'Guru Bahasa Inggris',
    'Guru Pendidikan Agama',
    'Staf Tata Usaha (TU)',
    'Bimbingan Konseling (BK)',
    'Wali Kelas & Kesiswaan',
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
    _nisController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nisController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _whatsappController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password))
      score++;
    if (RegExp(r'[0-9]').hasMatch(password) ||
        RegExp(r'[!@#\$&*~_.,]').hasMatch(password))
      score++;
    return score;
  }

  Future<void> _handleRegister() async {
    final nis = _nisController.text.trim();
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (nis.isEmpty) {
      _showSnackbar('Mohon masukkan Nomor Induk (NIS/NIP).', isError: true);
      return;
    }
    if (fullName.isEmpty) {
      _showSnackbar('Mohon masukkan nama lengkap.', isError: true);
      return;
    }
    if (email.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email)) {
      _showSnackbar('Mohon masukkan alamat email yang valid.', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackbar('Kata sandi minimal 6 karakter.', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnackbar('Konfirmasi kata sandi tidak cocok.', isError: true);
      return;
    }
    if (!_agreedToTerms) {
      _showSnackbar(
        'Anda harus menyetujui Ketentuan Layanan & Kebijakan Privasi.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        role: _selectedRole,
        studentId: nis,
        className: _selectedClass,
        whatsapp: whatsapp,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Akun berhasil dibuat & tersimpan di database!'),
              ],
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Gagal mendaftarkan akun.';
      if (e.code == 'email-already-in-use') {
        message = 'Email ini sudah terdaftar. Silakan langsung masuk.';
      } else if (e.code == 'weak-password') {
        message = 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter dengan kombinasi angka & simbol.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      _showSnackbar(message, isError: true);
    } on FirebaseException catch (e) {
      final detail = (e.message != null && e.message!.isNotEmpty)
          ? e.message!
          : 'Terjadi kesalahan Firestore [${e.code}].';
      _showSnackbar(detail, isError: true);
    } catch (e) {
      _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

  void _showClassPicker() {
    final list = _selectedRole == 'siswa' ? _studentClasses : _teacherRoles;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            Text(
              _selectedRole == 'siswa'
                  ? 'Pilih Kelas & Jurusan'
                  : 'Pilih Posisi / Unit Kerja',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = list[index];
                  final isSelected = item == _selectedClass;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF1D4ED8),
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedClass = item;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ketentuan Layanan & Kebijakan Privasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Ketentuan Akun PresensiKu\n'
                'Akun ini digunakan khusus untuk presensi digital terverifikasi sekolah dengan geolokasi GPS terintegrasi.\n\n'
                '2. Keamanan Data\n'
                'Data pribadi seperti NIS/NISN, nama, dan lokasi presensi dilindungi dan disimpan secara aman di Cloud Firestore dengan enkripsi SSL 256-bit.\n\n'
                '3. Kejujuran Presensi\n'
                'Manipulasi lokasi GPS (Fake GPS) atau penggunaan akun oleh orang lain merupakan pelanggaran disiplin sekolah.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                _agreedToTerms = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              'Saya Setuju',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculatePasswordStrength(_passwordController.text);
    final passwordsMatch =
        _passwordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Selection Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Peran Akun',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, size: 13, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text(
                    'Sinkron Dapodik Aktif',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Role Cards
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                roleKey: 'siswa',
                title: 'Siswa',
                subtitle: 'Registrasi Mandiri',
                icon: Icons.school_outlined,
                isSelected: _selectedRole == 'siswa',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                roleKey: 'guru',
                title: 'Guru & Staf',
                subtitle: 'Akun Pendidik',
                icon: Icons.work_outline_rounded,
                isSelected: _selectedRole == 'guru',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Field 1: NIS / NISN
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedRole == 'siswa'
                  ? 'Nomor Induk Siswa (NIS / NISN) *'
                  : 'NIP / NUPTK Guru & Staf *',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Cek Otomatis Dapodik',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _nisController,
          hint: _selectedRole == 'siswa'
              ? '210845 / 0071239841'
              : '198501152010011002',
          prefixIcon: Icons.badge_outlined,
          suffixIcon: _nisController.text.length >= 4
              ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 18,
                )
              : null,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),

        // Field 2: Nama Lengkap
        Text(
          _selectedRole == 'siswa'
              ? 'Nama Lengkap Siswa *'
              : 'Nama Lengkap Guru / Staf *',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _fullNameController,
          hint: 'Ahmad Rizky Pratama',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 14),

        // Field 3: Pilih Kelas & Jurusan
        Text(
          _selectedRole == 'siswa'
              ? 'Pilih Kelas & Jurusan *'
              : 'Mata Pelajaran / Unit Kerja *',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showClassPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedClass,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Field 4: Email Aktif
        const Text(
          'Email Aktif Siswa / Orang Tua *',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _emailController,
          hint: 'ahmad.rizky@student.sekolah.sch.id',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Untuk aktivasi verifikasi dan rekap notifikasi absensi bulanan',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(height: 14),

        // Field 5: WhatsApp
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nomor WhatsApp (Opsional / Wali Siswa)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Alert SMS/WA',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _whatsappController,
          hint: '081298457721',
          prefixIcon: Icons.phone_android_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        // Field 6: Buat Kata Sandi
        const Text(
          'Buat Kata Sandi *',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _passwordController,
          hint: '••••••••••••',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: const Color(0xFF64748B),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 8),

        // Password Strength Indicator (4 bars)
        _buildPasswordStrengthBar(strength),
        const SizedBox(height: 14),

        // Field 7: Konfirmasi Kata Sandi
        const Text(
          'Konfirmasi Kata Sandi *',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        _buildInputField(
          controller: _confirmPasswordController,
          hint: '••••••••••••',
          prefixIcon: Icons.history_rounded,
          obscureText: _obscureConfirmPassword,
          suffixIcon: passwordsMatch
              ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 18,
                )
              : IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Terms Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _agreedToTerms,
                activeColor: const Color(0xFF1D4ED8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (val) =>
                    setState(() => _agreedToTerms = val ?? false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: _showTermsDialog,
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: 'Saya menyetujui '),
                      TextSpan(
                        text: 'Ketentuan Layanan',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Kebijakan Privasi',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' PresensiKu Sekolah'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Primary Register Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              elevation: 2,
              shadowColor: const Color(0xFF1D4ED8).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedRole == 'siswa'
                            ? 'Daftar Akun Siswa'
                            : 'Daftar Akun Guru & Staf',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),

        // Notice Box: Belum terdaftar di database sekolah?
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Belum terdaftar di database sekolah?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pastikan NIS & NIK Anda telah diinput oleh Operator Tata Usaha / Wali Kelas sebelum melakukan registrasi akun mandiri.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Already have an account link
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sudah punya akun? ',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: const Text(
                  'Masuk Sekarang',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // SSL Badge & Version
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'Enkripsi SSL 256-bit',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(width: 8),
              Text(
                'v2.4.0 (Build 384)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            prefixIcon,
            color: const Color(0xFF64748B),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar(int strength) {
    Color barColor;
    String label;
    switch (strength) {
      case 1:
        barColor = const Color(0xFFEF4444);
        label = 'Kekuatan: Lemah';
        break;
      case 2:
        barColor = const Color(0xFFF59E0B);
        label = 'Kekuatan: Cukup';
        break;
      case 3:
        barColor = const Color(0xFF10B981);
        label = 'Kekuatan: Kuat';
        break;
      case 4:
        barColor = const Color(0xFF059669);
        label = 'Kekuatan: Sangat Kuat';
        break;
      default:
        barColor = Colors.grey.shade300;
        label = 'Kekuatan: Minimal 6 karakter';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isFilled ? barColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: strength > 0 ? barColor : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: strength > 0 ? barColor : Colors.grey,
                  ),
                ),
              ],
            ),
            const Text(
              '8+ Karakter, Huruf & Simbol',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleKey;
          if (_selectedRole == 'guru' &&
              !_teacherRoles.contains(_selectedClass)) {
            _selectedClass = _teacherRoles.first;
          } else if (_selectedRole == 'siswa' &&
              !_studentClasses.contains(_selectedClass)) {
            _selectedClass = _studentClasses.first;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
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
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF64748B),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
