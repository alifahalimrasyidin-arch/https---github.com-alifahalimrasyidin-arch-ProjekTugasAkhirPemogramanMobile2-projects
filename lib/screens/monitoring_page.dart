import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/plant.dart';
import 'add_plant_form.dart';
import '../data/plant_store.dart';
import '../widgets/plant_card.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // State untuk filter grafik
  String _selectedTimeFilter = 'Minggu';
  final List<String> _timeFilters = ['Minggu', 'Bulan', '6 Bulan', 'Tahun', '5 Tahun'];

 

  // Fungsi memunculkan pop-up tambah tanaman (Hampir full screen)
  void _showAddPlantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Wajib di-true agar tinggi bisa diatur lebih dari setengah layar
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85, // Mengambil 85% tinggi layar
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis kecil di atas modal (indikator pull down)
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Tambah tanaman', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Mau menanam apa?', style: TextStyle(color: context.muted)),
              SizedBox(height: 30),
              
                           _buildCategoryButton(Icons.eco, PlantCategory.sayurBuah),
              SizedBox(height: 15),
              _buildCategoryButton(Icons.local_florist, PlantCategory.hias),
              SizedBox(height: 15),
              _buildCategoryButton(Icons.water_drop, PlantCategory.hidroponik),
            ],
          ),
        );
      },
    );
  }
  // Desain tombol kategori di dalam Modal
  Widget _buildCategoryButton(IconData icon, PlantCategory category) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // tutup popup pilih kategori
        showAddPlantForm(context, category); // buka form
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: context.line),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: category.color.withValues(alpha: 0.1),
              child: Icon(icon, color: category.color),
            ),
            SizedBox(width: 20),
            Expanded(child: Text(category.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
                title: Text('Monitoring Kebun'), // Tombol back otomatis warna putih
        elevation: 0,
      ),
      
      // Tombol FAB (+) di pojok kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPlantModal,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white, size: 30),
      ),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN ATAS: GRAFIK & FILTER ---
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.surface,
                boxShadow: [BoxShadow(color: context.line, blurRadius: 5, spreadRadius: 1)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pertumbuhan tanaman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),
                  
                  // Deretan Filter (Bisa discroll menyamping jika kepanjangan)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _timeFilters.map((filter) {
                        final isSelected = _selectedTimeFilter == filter;
                        return Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : context.ink),
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
                  SizedBox(height: 20),
                  
                  // Area Placeholder Grafik
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.show_chart, size: 80, color: context.accent),
                        Text('Grafik $_selectedTimeFilter akan muncul di sini', style: TextStyle(color: context.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // --- BAGIAN BAWAH: LIST TANAMAN ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tanamanmu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // Tombol Sortir/Filter
                  IconButton(
                    icon: Icon(Icons.filter_list, color: context.accent),
                    onPressed: () {
                      // Munculkan popup sortir (nama, tanggal tambah, dll)
                    },
                  ),
                ],
              ),
            ),
            
                       // Daftar tanaman: otomatis diperbarui saat plantStore berubah
            ListenableBuilder(
              listenable: plantStore,
              builder: (context, _) {
                final plants = plantStore.plants;

                if (plants.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: 60.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.energy_savings_leaf_outlined, size: 80, color: context.muted),
                          SizedBox(height: 15),
                          Text(
                            'Belum ada tanaman\nKetuk + untuk menambah tanaman pertamamu',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.muted, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Tanaman terbaru di paling atas
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    children: [
                      for (final plant in plants.reversed) PlantCard(plant: plant),
                    ],
                  ),
                );
              },
            ),
              // Tempat menaruh desain card (jika datanya sudah ada)
              SizedBox(),
              
            SizedBox(height: 100), // Spasi bawah agar tidak tertutup FAB
          ],
        ),
      ),
    );
  }
}