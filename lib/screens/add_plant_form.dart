import 'package:flutter/material.dart';
import '../data/plant_store.dart';
import '../models/plant.dart';
import '../theme/app_theme.dart';

const String kOtherType = 'Lainnya';

/// Menampilkan popup form tambah tanaman untuk satu kategori.
void showAddPlantForm(BuildContext context, PlantCategory category) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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

  void _submit() {
    final nameOk = _formKey.currentState!.validate();
    setState(() {
      _typeError = _type == null ? 'Pilih jenis tanaman dulu' : null;
    });
    if (!nameOk || _type == null) return;

    // "Lainnya" nanti diarahkan ke form yang berbeda (belum dibuat).
    if (_type == kOtherType) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Form untuk jenis lainnya segera hadir')),
      );
      return;
    }

    plantStore.add(Plant(
      name: _nameController.text.trim(),
      type: _type!,
      category: widget.category,
      careType: careTypeOf(widget.category, _type!),
      withSemai: _withSemai,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final entries = [...plantCatalog[category]!, kOtherType]
        .map((t) => DropdownMenuEntry<String>(value: t, label: t))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah ${category.label.toLowerCase()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nama tanaman',
                hintText: 'Contoh: Kangkung balkon',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama tanaman wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero, // lebar penuh
              label: const Text('Jenis tanaman'),
              hintText: 'Pilih atau ketik untuk mencari',
              enableFilter: true, // daftar menyaring saat mengetik
              requestFocusOnTap: true, // field bisa diketik
              menuHeight: 240,
              errorText: _typeError,
              dropdownMenuEntries: entries,
              onSelected: (v) => setState(() {
                _type = v;
                _typeError = null;
                _withSemai = false;
              }),
            ),
            if (_type != null &&
                careTypeOf(widget.category, _type!) == CareType.taburBuah)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mulai dari masa semai'),
                subtitle: const Text(
                    'Aktifkan kalau bibit disemai dulu sebelum ditanam.'),
                value: _withSemai,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _withSemai = v),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_type == kOtherType ? 'Lanjut' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}