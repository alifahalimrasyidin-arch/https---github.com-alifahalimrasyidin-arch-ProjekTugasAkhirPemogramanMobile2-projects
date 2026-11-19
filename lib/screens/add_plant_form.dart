import 'package:flutter/material.dart';

import '../data/plant_store.dart';
import '../models/plant.dart';
import '../theme/app_theme.dart';

const String kOtherType = 'Lainnya';

/// Menampilkan popup form tambah tanaman dari bawah layar (Bottom Sheet)
/// sesuai kategori tanaman yang dipilih.
void showAddPlantForm(BuildContext context, PlantCategory category) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      // Menyesuaikan jarak bawah otomatis saat keyboard layar muncul
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AddPlantForm(category: category),
    ),
  );
}

class AddPlantForm extends StatefulWidget {
  final PlantCategory category;
  const AddPlantForm({super.key, required this.category});

  @override
  State<AddPlantForm> createState() => _AddPlantFormState();
}

class _AddPlantFormState extends State<AddPlantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _type;
  bool _withSemai = false;
  String? _typeError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Memvalidasi input lalu menyimpan tanaman baru ke dalam plantStore.
  void _submit() {
    final nameOk = _formKey.currentState!.validate();
    setState(() {
      _typeError = _type == null ? 'Pilih jenis tanaman dulu' : null;
    });
    if (!nameOk || _type == null) return;

    // Jika memilih "Lainnya", tampilkan info sementara
    if (_type == kOtherType) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Form untuk jenis lainnya segera hadir')),
      );
      return;
    }

    // Simpan data tanaman baru ke store dan tutup popup form
    plantStore.add(
      Plant(
        name: _nameController.text.trim(),
        type: _type!,
        category: widget.category,
        careType: careTypeOf(widget.category, _type!),
        withSemai: _withSemai,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    // Menyusun daftar pilihan jenis tanaman berdasarkan kategori + opsi 'Lainnya'
    final entries = [
      ...plantCatalog[category]!,
      kOtherType,
    ].map((t) => DropdownMenuEntry<String>(value: t, label: t)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Garis indikator geser turun di puncak modal
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header judul form beserta ikon kategori tanaman
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tambah ${category.label.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Kolom input nama tanaman
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nama tanaman',
                hintText: 'Contoh: Kangkung balkon',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama tanaman wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),

            // Dropdown jenis tanaman dengan fitur ketik untuk mencari
            DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero,
              label: const Text('Jenis tanaman'),
              hintText: 'Pilih atau ketik untuk mencari',
              enableFilter: true, // Menyaring daftar saat pengguna mengetik
              requestFocusOnTap: true,
              menuHeight: 240,
              errorText: _typeError,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              dropdownMenuEntries: entries,
              onSelected: (v) => setState(() {
                _type = v;
                _typeError = null;
                _withSemai = false;
              }),
            ),

            // Opsi sakelar masa semai (khusus jenis tanaman tabur buah)
            if (_type != null &&
                careTypeOf(widget.category, _type!) == CareType.taburBuah) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.tint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.line),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Mulai dari masa semai',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: context.ink,
                    ),
                  ),
                  subtitle: Text(
                    'Aktifkan kalau bibit disemai dulu sebelum ditanam.',
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                  value: _withSemai,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _withSemai = v),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Tombol simpan utama
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _type == kOtherType ? 'Lanjut' : 'Tambah',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
