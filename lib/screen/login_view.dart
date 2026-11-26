import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/auth_service.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginView({super.key, required this.onSwitchToRegister});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const String _prefRememberMe = 'remember_me';
  static const String _prefIdentifier = 'remembered_identifier';
  static const String _prefRole = 'remembered_role';

  final AuthService _authService = AuthService();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'siswa'; // 'siswa' atau 'guru'
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isValidFormat = false;

  @override
  void initState() {
    super.initState();
    _identifierController.addListener(_checkFormat);
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _identifierController.removeListener(_checkFormat);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Memuat status 'Ingat saya', identitas, dan peran tersimpan
  Future<void> _loadRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_prefRememberMe) ?? true;
    final savedIdentifier = prefs.getString(_prefIdentifier) ?? '';
    final savedRole = prefs.getString(_prefRole);

    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember && savedIdentifier.isNotEmpty) {
        _identifierController.text = savedIdentifier;
      }
      if (remember && (savedRole == 'siswa' || savedRole == 'guru')) {
        _selectedRole = savedRole!;
      }
    });
    _checkFormat();
  }

  /// Menyimpan atau menghapus identitas login berdasarkan checkbox 'Ingat saya'
  Future<void> _saveRememberedLogin(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefRememberMe, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_prefIdentifier, identifier.trim());
      await prefs.setString(_prefRole, _selectedRole);
    } else {
      await prefs.remove(_prefIdentifier);
      await prefs.remove(_prefRole);
    }
  }

  void _checkFormat() {
    final text = _identifierController.text.trim();
    final bool isEmail = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(text);
    final bool isNumberId = RegExp(r'^[0-9]{4,18}$').hasMatch(text);

    final valid = isEmail || isNumberId;
    if (valid != _isValidFormat) {
      setState(() {
        _isValidFormat = valid;
      });
    }
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty) {
      _showSnackbar('Mohon masukkan NIS atau Email akun Anda.', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showSnackbar('Mohon masukkan kata sandi Anda.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });
    isSigningIn.value = true;

    try {
      await _authService.signIn(
        identifier: identifier,
        password: password,
        role: _selectedRole,
      );
      
      // Simpan preferensi Ingat Saya setelah berhasil masuk
      await _saveRememberedLogin(identifier);

      isSigningIn.value = false;
      if (mounted) {
        _showSnackbar('Berhasil masuk ke PresensiKu!', isError: false);
      }
    } on FirebaseAuthException catch (e) {
      isSigningIn.value = false;
      String message = 'Terjadi kesalahan saat masuk.';
      if (e.code == 'wrong-role') {
        message =
            e.message ??
            'Peran akun tidak sesuai dengan pilihan peran saat masuk.';
      } else if (e.code == 'user-not-found') {
        message =
            'Akun tidak ditemukan. Silakan periksa NIS/Email atau daftar baru.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Kata sandi salah. Silakan coba lagi.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'user-disabled') {
        message = 'Akun Anda dinonaktifkan oleh pihak sekolah.';
      } else if (e.code == 'too-many-requests') {
        message =
            'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      _showSnackbar(message, isError: true);
    } catch (e) {
      isSigningIn.value = false;
      _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      isSigningIn.value = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger =
        rootScaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final currentInput = _identifierController.text.trim();
    final resetController = TextEditingController(
      text: currentInput.contains('@') ? currentInput : '',
    );
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
              const SizedBox(height: 18),
              const Text(
                'Pemulihan Kata Sandi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan alamat email akun yang terdaftar (bukan NIS/NIP) untuk menerima tautan reset kata sandi.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (errorText != null) {
                    setModalState(() => errorText = null);
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF64748B),
                  ),
                  hintText:
                      'Masukkan email terdaftar (contoh: nama@sekolah.sch.id)',
                  errorText: errorText,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final email = resetController.text.trim();
                    if (email.isEmpty ||
                        !RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(email)) {
                      setModalState(() {
                        errorText = 'Masukkan alamat email yang valid.';
                      });
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      await _authService.sendPasswordReset(email);
                      _showSnackbar(
                        'Tautan pemulihan kata sandi telah dikirim ke $email',
                      );
                    } catch (e) {
                      _showSnackbar(
                        'Gagal mengirim email pemulihan: ${e.toString()}',
                        isError: true,
                      );
                    }
                  },
                  child: const Text(
                    'Kirim Tautan Reset',
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
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_outlined, color: Color(0xFF1D4ED8)),
            SizedBox(width: 10),
            Text('Layanan Bantuan TU'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jika Anda mengalami kendala NIS/NIP tidak terdaftar atau lupa email akun:',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 18, color: Color(0xFF0F172A)),
                SizedBox(width: 8),
                Text(
                  'Admin TU: (021) 876-54321',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.mail_outline, size: 18, color: Color(0xFF0F172A)),
                SizedBox(width: 8),
                Text(
                  'Email: admin@sekolah.sch.id',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 18,
                  color: Color(0xFF0F172A),
                ),
                SizedBox(width: 8),
                Text(
                  'Jam Kerja: 07.00 - 15.30 WIB',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(color: Color(0xFF1D4ED8)),
            ),
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
        // Role Selector Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PILIH PERAN ANDA',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
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
                  Icon(Icons.verified, size: 13, color: Color(0xFF059669)),
                  SizedBox(width: 4),
                  Text(
                    'Terverifikasi Kemdikbud',
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

        // Role Selector Cards
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                roleKey: 'siswa',
                title: 'Siswa',
                subtitle: 'Pakai NIS / Email',
                icon: Icons.badge_outlined,
                isSelected: _selectedRole == 'siswa',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleCard(
                roleKey: 'guru',
                title: 'Guru & Staf',
                subtitle: 'Pakai NIP / NUPTK',
                icon: Icons.work_outline_rounded,
                isSelected: _selectedRole == 'guru',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Input 1: NIS or Email
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedRole == 'siswa'
                  ? 'NIS atau Email Siswa *'
                  : 'NIP / NUPTK atau Email Guru & Staf *',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            if (_isValidFormat)
              const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Format valid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isValidFormat
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: Color(0xFF64748B),
                size: 20,
              ),
              hintText: _selectedRole == 'siswa'
                  ? '210845'
                  : '198501152010011002',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              suffixIcon: _identifierController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      onPressed: () {
                        _identifierController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Input 2: Password
        const Text(
          'Kata Sandi *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF64748B),
                size: 20,
              ),
              hintText: 'Masukkan kata sandi akun',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) async {
                      final checked = val ?? false;
                      setState(() {
                        _rememberMe = checked;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_prefRememberMe, checked);
                      if (!checked) {
                        await prefs.remove(_prefIdentifier);
                        await prefs.remove(_prefRole);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ingat saya',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showForgotPasswordSheet,
              child: const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Primary Button: Masuk Sekarang ->
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
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Masuk Sekarang',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 18),

        // Radius / GPS Notice Banner
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
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.near_me_outlined,
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
                      'Verifikasi Radius Presensi Aktif',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Presensi dapat dilakukan saat berada dalam radius 150m dari gerbang sekolah. Pastikan izin GPS aktif.',
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
        const SizedBox(height: 24),

        // Footer Support
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Kendala akun sekolah? ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: _showHelpDialog,
                child: const Text(
                  'Hubungi Operator / TU',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Version & Security badge
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'v2.4.0 (Build 384)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 8),
              Text('•', style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(width: 8),
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
            ],
          ),
        ),
        const SizedBox(height: 20),
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
          _checkFormat();
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
                      color: Color(0xFF1D4ED8),
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