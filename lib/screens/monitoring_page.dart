import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/plant.dart';
import 'add_plant_form.dart';
import '../data/plant_store.dart';
import '../widgets/plant_card.dart';

/// Halaman Monitoring Kebun: menampilkan grafik pertumbuhan tanaman,
/// daftar seluruh tanaman milik pengguna, serta tombol tambah tanaman baru.
class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // Filter rentang waktu yang sedang aktif pada grafik
  String _selectedTimeFilter = 'Minggu';
  final List<String> _timeFilters = [
    'Minggu',
    'Bulan',
    '6 Bulan',
    'Tahun',
    '5 Tahun'
  ];

  /// Menampilkan modal dari bawah untuk memilih kategori tanaman sebelum mengisi form.
  void _showAddPlantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar tinggi modal dapat diatur hingga 85% layar
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Garis indikator geser turun di bagian atas modal
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.line,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Tambah tanaman',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mau menanam apa hari ini?',
                  style: TextStyle(color: context.muted, fontSize: 14),
                ),
                const SizedBox(height: 26),

                // Tiga pilihan kategori utama tanaman
                _buildCategoryButton(Icons.eco, PlantCategory.sayurBuah),
                const SizedBox(height: 14),
                _buildCategoryButton(Icons.local_florist, PlantCategory.hias),
                const SizedBox(height: 14),
                _buildCategoryButton(
                    Icons.water_drop, PlantCategory.hidroponik),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tombol pilihan kategori tanaman di dalam modal tambah tanaman.
  Widget _buildCategoryButton(IconData icon, PlantCategory category) {
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(context); // Tutup modal pilih kategori
          showAddPlantForm(context, category); // Buka form input tanaman
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: context.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Lingkaran ikon dengan latar transparan sesuai warna kategori
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: category.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.ink,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: context.muted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = context.isDark ? context.bg : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('Monitoring Kebun'),
        elevation: 0,
      ),

      // Tombol aksi melayang (+) di pojok kanan bawah untuk menambah tanaman
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlantModal,
        backgroundColor: AppColors.primary,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian atas: panel grafik dan filter waktu
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              decoration: BoxDecoration(
                color: pageBg,
                border: Border(bottom: BorderSide(color: context.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pertumbuhan tanaman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Deretan chip filter waktu yang dapat digeser ke samping
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _timeFilters.map((filter) {
                        final isSelected = _selectedTimeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            showCheckmark: false,
                            backgroundColor: pageBg,
                            selectedColor: AppColors.primary,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.line,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : context.ink,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTimeFilter = filter;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kotak area tampilan grafik pertumbuhan
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.tint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.show_chart_rounded,
                              size: 40, color: context.accent),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Grafik $_selectedTimeFilter akan muncul di sini',
                          style: TextStyle(color: context.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bagian bawah: header dan daftar tanaman
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tanamanmu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                  // Tombol filter/urutkan daftar tanaman
                  IconButton(
                    icon: Icon(Icons.filter_list_rounded, color: context.accent),
                    onPressed: () {
                      // Tempat memunculkan opsi sortir (nama, tanggal tanam, dll)
                    },
                  ),
                ],
              ),
            ),

            // Mendengarkan perubahan data dari plantStore secara real-time
            ListenableBuilder(
              listenable: plantStore,
              builder: (context, _) {
                final plants = plantStore.plants;

                // Tampilan kosong jika belum ada tanaman yang ditambahkan
                if (plants.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.tint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.energy_savings_leaf_outlined,
                              size: 56,
                              color: context.accent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada tanaman',
                            style: TextStyle(
                              color: context.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ketuk tombol + di pojok kanan bawah\nuntuk menambah tanaman pertamamu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Menampilkan daftar kartu tanaman (urutan terbaru di paling atas)
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Column(
                    children: [
                      for (final plant in plants.reversed)
                        PlantCard(plant: plant),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 100), // Spasi bawah agar kartu terbawah tidak tertutup FAB
          ],
        ),
      ),
    );
  }
}