import 'package:flutter/material.dart';
import 'login_view.dart';
import 'register_view.dart';

class AuthScreen extends StatefulWidget {
  final int initialTabIndex; // 0 for Masuk, 1 for Daftar Baru

  const AuthScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late int _selectedTab; // 0 = Masuk, 1 = Daftar Baru

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Top Icon / App Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? const Color(0xFFE0E7FF)
                        : const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedTab == 0
                            ? const Color(0xFF6366F1).withOpacity(0.15)
                            : const Color(0xFF1D4ED8).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _selectedTab == 0
                        ? const Icon(
                            Icons.co_present_outlined,
                            size: 28,
                            color: Color(0xFF1E40AF),
                          )
                        : const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top Badge Pill: • Presensi Digital Cerdas & Terpadu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Presensi Digital Cerdas & Terpadu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // App Title
                const Text(
                  'PresensiKu',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _selectedTab == 0
                        ? 'Selamat datang, silakan masuk untuk mencatat kehadiran hari ini.'
                        : 'Buat akun siswa baru untuk mulai mencatat absensi digital sekolah.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Segmented Switcher: [Masuk] [Daftar Baru]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      // Tab 0: Masuk
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 0
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_selectedTab == 1) ...[
                                  const Icon(Icons.login_rounded, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                                    color: _selectedTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Tab 1: Daftar Baru
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedTab == 1
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add_alt_1_outlined,
                                  size: 16,
                                  color: _selectedTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Daftar Baru',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                                    color: _selectedTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Views
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _selectedTab == 0
                      ? LoginView(
                          key: const ValueKey('login'),
                          onSwitchToRegister: () => setState(() => _selectedTab = 1),
                        )
                      : RegisterView(
                          key: const ValueKey('register'),
                          onSwitchToLogin: () => setState(() => _selectedTab = 0),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

