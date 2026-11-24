import 'package:flutter/material.dart';

class TeacherWeeklyTrendCard extends StatefulWidget {
  final String className;

  const TeacherWeeklyTrendCard({
    super.key,
    this.className = 'Kelas XII RPL 1',
  });

  @override
  State<TeacherWeeklyTrendCard> createState() => _TeacherWeeklyTrendCardState();
}

class _TeacherWeeklyTrendCardState extends State<TeacherWeeklyTrendCard> {
  int _selectedFilterIndex = 0; // 0: Minggu Ini, 1: Bulan Ini

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          // Header: Icon + Title & Subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insert_chart_outlined_rounded,
                  size: 18,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tren Kehadiran Mingguan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Senin – Jumat • ${widget.className}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Segmented Toggle: Minggu Ini | Bulan Ini
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTogglePill('Minggu Ini', 0),
                _buildTogglePill('Bulan Ini', 1),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Visual Bar Chart (Senin s/d Jumat)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBarColumn(
                day: 'Sen',
                percentage: 97,
                barHeight: 88,
                isActive: false,
                isToday: false,
              ),
              _buildBarColumn(
                day: 'Sel',
                percentage: 94,
                barHeight: 80,
                isActive: false,
                isToday: false,
              ),
              _buildBarColumn(
                day: 'Rab',
                percentage: 97,
                barHeight: 88,
                isActive: false,
                isToday: false,
              ),
              _buildBarColumn(
                day: 'Kam',
                percentage: 92,
                barHeight: 76,
                isActive: true,
                isToday: true,
              ),
              _buildTargetColumn(
                day: 'Jum',
                targetPercentage: 95,
                barHeight: 84,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend Bar: Hadir Tepat, Terlambat, Izin/Sakit, Alpa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF1E3A8A), 'Hadir Tepat'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFFF59E0B), 'Terlambat'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFF93C5FD), 'Izin/Sakit'),
              const SizedBox(width: 12),
              _buildLegendItem(const Color(0xFFDC2626), 'Alpa'),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Summary Banner: Rata-rata 95.0% • Disiplin Unggul
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 15,
                  color: Color(0xFF059669),
                ),
                SizedBox(width: 6),
                Text(
                  'Rata-rata: 95.0% • Disiplin Unggul',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTogglePill(String title, int index) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildBarColumn({
    required String day,
    required int percentage,
    required double barHeight,
    required bool isActive,
    required bool isToday,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top label percentage
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D4ED8),
              ),
            ),
          )
        else
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        const SizedBox(height: 6),

        // Rounded Bar
        Container(
          width: 32,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isToday
                  ? [
                      const Color(0xFF1E3A8A),
                      const Color(0xFF1D4ED8),
                    ]
                  : [
                      const Color(0xFF3B82F6),
                      const Color(0xFF1D4ED8),
                    ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isToday)
                const Icon(
                  Icons.access_time_filled_rounded,
                  size: 14,
                  color: Colors.white,
                )
              else
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Day label
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetColumn({
    required String day,
    required int targetPercentage,
    required double barHeight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Target\n95%',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),

        // Dashed outline / subtle placeholder bar
        Container(
          width: 32,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF93C5FD),
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Text(
              'Fit',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF93C5FD),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        Text(
          day,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.5,
          height: 6.5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

