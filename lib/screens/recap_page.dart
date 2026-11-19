import 'package:flutter/material.dart';
import '../data/plant_store.dart';
import '../theme/app_theme.dart';
import 'recap_story_page.dart';

/// Halaman Rekap Kita: pemutar rekap periode, statistik pencapaian, dan daftar panen terbaik pengguna.
class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  String _selectedFilter = 'Bulan Ini';
  final List<String> _filters = ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

  /// Menghitung jumlah hari dari filter terpilih lalu membuka RecapStoryPage.
  void _playRecapStory() {
    final days = _selectedFilter == 'Minggu Ini'
        ? 7
        : (_selectedFilter == 'Bulan Ini' ? 30 : 365);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecapStoryPage(periodLabel: _selectedFilter, days: days),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = context.isDark ? context.bg : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        elevation: 0,
        title: const Text('Rekap Kita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian atas: pemutar rekap priode
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: context.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lihat perjalanan kebunmu',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dropdown pemilih rentang waktu rekap
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: context.accent),
                        items: _filters.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: context.ink,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedFilter = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol utama untuk memutar cerita rekap
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _playRecapStory,
                      icon:
                          Icon(Icons.play_circle_fill, color: context.accent),
                      label: Text(
                        'Putar rekap $_selectedFilter',
                        style: TextStyle(
                          color: context.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.surface,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Bagian tengah: Statistik pencapaian
            Text(
              'Pencapaianmu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: plantStore,
              builder: (context, _) => Row(
                children: [
                  _buildStatCard(
                    context,
                    Icons.eco,
                    'Total\nTanaman',
                    '${plantStore.totalPlantsEver}',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    Icons.water_drop,
                    'Aksi\nPerawatan',
                    '${plantStore.totalCareActions}',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    Icons.emoji_events,
                    'Panen\nberhasil',
                    '${plantStore.totalHarvests}',
                    AppColors.harvest,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Bagian bawah: daftar panen terbaik
            Text(
              'Panen terbaik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 14),
            ListenableBuilder(
              listenable: plantStore,
              builder: (context, _) {
                final list = plantStore.harvests.reversed.take(5).toList();
                // Tampilan kosong saat belum ada panen tercatat
                if (list.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.line),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off,
                            size: 44, color: context.muted),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada panen tercatat',
                          style: TextStyle(color: context.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Daftar maksimal 5 panen terbaru
                return Column(
                  children: [
                    for (final h in list)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.harvest.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.emoji_events,
                                  color: AppColors.harvest, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: context.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${h.type} • ${h.how}',
                                    style: TextStyle(
                                        color: context.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${h.at.day}/${h.at.month}/${h.at.year}',
                              style:
                                  TextStyle(color: context.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu statistik untuk menampilkan ringkasan angka pencapaian.
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.muted,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}