import 'package:flutter/material.dart';
import '../data/plant_store.dart';
import '../theme/app_theme.dart';
import 'recap_story_page.dart';

class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapPageState extends State<RecapPage> {
  String _selectedFilter = 'Bulan Ini';
  final List<String> _filters = ['Minggu Ini', 'Bulan Ini', 'Tahun Ini'];

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
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
                elevation: 0,
        title: Text('Rekap Kita'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTU GENERATE RECAP ---
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2, offset: Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 50),
                  SizedBox(height: 15),
                  Text(
                    'Lihat perjalanan kebunmu',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  
                  // Dropdown Filter Waktu
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: context.accent),
                        items: _filters.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Tombol Play Recap
                  ElevatedButton.icon(
                    onPressed: _playRecapStory,
                    icon: Icon(Icons.play_circle_fill, color: context.accent),
                    label: Text('Putar rekap $_selectedFilter', style: TextStyle(color: context.accent, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.surface,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 35),
            
            // --- STATISTIK SEPANJANG WAKTU (KOSONG) ---
            Text('Pencapaianmu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            ListenableBuilder(
              listenable: plantStore,
              builder: (context, _) => Row(
                children: [
                  _buildStatCard(Icons.eco, 'Total\nTanaman', '${plantStore.totalPlantsEver}', AppColors.primary),
                  SizedBox(width: 15),
                  _buildStatCard(Icons.water_drop, 'Aksi\nPerawatan', '${plantStore.totalCareActions}', AppColors.primary),
                  SizedBox(width: 15),
                  _buildStatCard(Icons.emoji_events, 'Panen\nberhasil', '${plantStore.totalHarvests}', AppColors.harvest),
                ],
              ),
            ),
            
            SizedBox(height: 35),

            // --- HALL OF FAME PANEN (KOSONG) ---
            Text('Panen terbaik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ListenableBuilder(
              listenable: plantStore,
              builder: (context, _) {
                final list = plantStore.harvests.reversed.take(5).toList();
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 14),
                        Icon(Icons.history_toggle_off, size: 50, color: context.line),
                        SizedBox(height: 10),
                        Text(
                          'Belum ada panen tercatat',
                          style: TextStyle(color: context.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final h in list)
                      Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, color: AppColors.harvest),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${h.type}, ${h.how}',
                                    style: TextStyle(color: context.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${h.at.day}/${h.at.month}/${h.at.year}',
                              style: TextStyle(color: context.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // Desain kotak statistik kecil
  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: context.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.muted)),
          ],
        ),
      ),
    );
  }
}