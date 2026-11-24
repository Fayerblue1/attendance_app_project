import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequestPage extends StatelessWidget {
  final Stream<QuerySnapshot>? leaveRequestsStream;
  final VoidCallback onOpenLeaveDialog;

  const LeaveRequestPage({
    super.key,
    required this.leaveRequestsStream,
    required this.onOpenLeaveDialog,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengajuan Izin / Sakit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Daftar riwayat permohonan dispensasi siswa.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: onOpenLeaveDialog,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Ajukan', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (leaveRequestsStream == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: leaveRequestsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 44, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada pengajuan izin atau sakit.',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onOpenLeaveDialog,
                          child: const Text('Buat Pengajuan Baru Sekarang'),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final category = data['category'] ?? 'Izin';
                    final date = data['date'] ?? '';
                    final reason = data['reason'] ?? '';
                    final status = data['status'] ?? 'Menunggu Verifikasi';

                    final isApproved = status.toString().toLowerCase().contains('setuju');
                    final isRejected = status.toString().toLowerCase().contains('tolak');

                    return Container(
                      padding: const EdgeInsets.all(14),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: category == 'Sakit'
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      category == 'Sakit' ? Icons.healing_rounded : Icons.event_note_rounded,
                                      size: 16,
                                      color: category == 'Sakit'
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isApproved
                                      ? const Color(0xFFD1FAE5)
                                      : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isApproved
                                        ? const Color(0xFF059669)
                                        : (isRejected ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Tanggal: $date', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Text(
                            reason,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.35),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

