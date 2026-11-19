import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/plant_store.dart';
import '../models/care_rules.dart';
import '../models/plant.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// Halaman detail satu tanaman: menampilkan status tumbuh, tugas perawatan harian,
/// peringatan cuaca, fitur panen, catatan, galeri foto, serta opsi hapus tanaman.
class PlantDetailPage extends StatelessWidget {
  final Plant plant;
  const PlantDetailPage({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final pageBg = context.isDark ? context.bg : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(plant.name),
        elevation: 0,
      ),
      // Mendengarkan perubahan data tanaman dan cuaca secara real-time
      body: ListenableBuilder(
        listenable: Listenable.merge([plantStore, weatherStore]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            _header(context),
            const SizedBox(height: 22),
            ..._careSection(context),
            const SizedBox(height: 26),
            ..._notesSection(context),
            const SizedBox(height: 26),
            ..._photoSection(context),
            const SizedBox(height: 24),
            Divider(color: context.line),
            const SizedBox(height: 8),
            ..._dangerSection(context),
          ],
        ),
      ),
    );
  }

  // Bagian 1: Header Kartu Identitas Tanaman 
  Widget _header(BuildContext context) {
    final day = DateTime.now().difference(plant.plantedAt).inDays + 1;
    final stageText = plant.stage == PlantStage.semai ? 'Masa semai' : 'Tumbuh';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: plant.category.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: plant.category.color.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Row(
        children: [
          // Kotak ikon kategori tanaman
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(plant.category.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          // Nama, jenis, dan fase pertumbuhan tanaman
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${plant.type} • ${plant.category.label}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stageText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Badge penanda usia tanam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Hari ke-$day',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bagian 2: Perawatan, Cuaca & Panen
  List<Widget> _careSection(BuildContext context) {
    final rules = plant.rules;
    if (rules == null) {
      return [
        _info(context, Icons.construction_outlined,
            'Fitur perawatan untuk jenis ini segera hadir.'),
      ];
    }

    // Jika tanaman masih berada pada tahap semai
    if (plant.stage == PlantStage.semai) {
      return [
        _title(context, 'Masa semai'),
        const SizedBox(height: 4),
        Text(
          'Hari ke-${plant.daysInStage + 1} dari ${plant.semaiLength}',
          style: TextStyle(color: context.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (plant.semaiReady)
          _alert(
            context,
            Icons.notifications_active_outlined,
            'Siap pindah tanah',
            'Masa semai sudah selesai. Pindahkan bibit ke tanah.',
            action: 'Sudah pindah tanah',
            onTap: () => plantStore.startGrowing(plant),
          ),
        _checklist(context, rules.semaiTasks),
        if (!plant.semaiReady)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => plantStore.startGrowing(plant),
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('Lewati masa semai'),
            ),
          ),
      ];
    }

    // Jika tanaman sudah masuk tahap tumbuh
    final hasHarvest = rules.harvestMode != HarvestMode.none;
    return [
      _title(context, hasHarvest ? 'Perawatan hari ini' : 'Perawatan'),
      const SizedBox(height: 10),
      if (rules.lightNote != null) ...[
        _info(context, Icons.wb_sunny_outlined, rules.lightNote!),
        const SizedBox(height: 12),
      ],
      if (plant.category != PlantCategory.hidroponik)
        ..._weatherNotes(context),
      if (plant.mustPull)
        _alert(
          context,
          Icons.warning_amber_rounded,
          'Wajib cabut akar',
          'Sudah ${rules.maxCuts} kali panen potong. Tanaman perlu dicabut akarnya.',
        )
      else if (plant.canHarvest)
        _alert(
          context,
          Icons.notifications_active_outlined,
          'Sudah bisa dipanen',
          plant.cutCount == 0
              ? 'Tanaman sudah cukup umur untuk dipanen.'
              : 'Tanaman tumbuh lagi dan siap dipanen.',
        )
      else if (plant.canPick && plant.pickCount == 0)
        _alert(
          context,
          Icons.notifications_active_outlined,
          'Waktunya pantau buah',
          'Mulai sekarang kamu bisa memangkas dan memantau buah. Catat setiap kali memetik.',
        ),
      _checklist(context, rules.tasks),

      // Tombol panen potong / cabut akar
      if (plant.canHarvest || plant.mustPull) ...[
        const SizedBox(height: 20),
        _title(context, 'Panen'),
        const SizedBox(height: 10),
        if (!plant.mustPull)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => plantStore.harvestCut(plant),
              icon: const Icon(Icons.content_cut),
              label: Text(
                  'Panen potong (${plant.cutCount + 1} dari ${rules.maxCuts})'),
            ),
          ),
        if (!plant.mustPull) const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmPull(context),
            icon: const Icon(Icons.eco),
            label: const Text('Panen cabut akar'),
          ),
        ),
      ],

      // Tombol catat petik buah (untuk tanaman berbuah)
      if (plant.canPick) ...[
        const SizedBox(height: 20),
        _title(context, 'Panen'),
        const SizedBox(height: 4),
        Text(
          'Sudah dipetik ${plant.pickCount} kali',
          style: TextStyle(color: context.muted, fontSize: 13),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => plantStore.pickFruit(plant),
            icon: const Icon(Icons.shopping_basket_outlined),
            label: const Text('Catat petik buah'),
          ),
        ),
      ],
    ];
  }

  /// Menampilkan saran perawatan otomatis berdasarkan kondisi cuaca hari ini.
  List<Widget> _weatherNotes(BuildContext context) {
    final w = weatherStore.today;
    if (w == null) return [];
    final hasSiram =
        plant.rules?.tasks.any((t) => t.kind == CareKind.siram) ?? false;
    return [
      if (w.rainy && hasSiram)
        _alert(
          context,
          Icons.water_drop_outlined,
          'Diperkirakan hujan hari ini',
          'Peluang hujan ${w.rainChance}%. Penyiraman bisa ditunda kalau tanamanmu di luar ruangan.',
          action: plant.doneToday(CareKind.siram)
              ? null
              : 'Anggap sudah disiram hujan',
          onTap: () => plantStore.logCare(plant, CareKind.siram),
        ),
      if (w.hot && plant.careType == CareType.hiasSulit)
        _alert(
          context,
          Icons.wb_sunny_outlined,
          'Panas tinggi hari ini',
          'Suhu bisa mencapai ${w.tempMax.round()}°C. Pindahkan tanaman ke tempat teduh.',
        ),
    ];
  }

  /// Daftar tugas perawatan yang jatuh tempo hari ini.
  Widget _checklist(BuildContext context, List<RoutineTask> tasks) {
    final visible = tasks
        .where((t) =>
            t.fromDay <= plant.daysInStage &&
            (plant.doneToday(t.kind) || plant.dueNow(t)))
        .toList();

    if (visible.isEmpty) {
      return _info(
          context, Icons.check_circle_outline, 'Tidak ada tugas hari ini.');
    }

    return Column(
      children: [
        for (final t in visible)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: plant.doneToday(t.kind) ? context.tint : context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: plant.doneToday(t.kind)
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : context.line,
              ),
            ),
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              value: plant.doneToday(t.kind),
              onChanged: plant.doneToday(t.kind)
                  ? null
                  : (_) => plantStore.logCare(plant, t.kind),
              title: Text(
                t.label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.ink,
                ),
              ),
              subtitle: Text(
                t.everyDays <= 1 ? 'Setiap hari' : 'Setiap ${t.everyDays} hari',
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  /// Konfirmasi sebelum melakukan panen cabut akar
  Future<void> _confirmPull(BuildContext context) async {
    final ok = await _confirm(
      context,
      'Panen dan cabut akar?',
      'Tanaman dianggap berhasil dipanen dan kartunya dihapus dari daftar.',
      'Panen',
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    plantStore.harvestPull(plant);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Panen berhasil dicatat.')),
    );
  }

  // Bagian 3: Catatan Perkembangan Tanaman
  List<Widget> _notesSection(BuildContext context) {
    return [
      _title(context, 'Catatan'),
      const SizedBox(height: 8),
      if (plant.notes.isEmpty)
        Text('Belum ada catatan.', style: TextStyle(color: context.muted)),
      for (final n in plant.notes.reversed)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(n.text, style: const TextStyle(height: 1.4)),
        ),
      OutlinedButton.icon(
        onPressed: () => _addNote(context),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Tambah catatan'),
      ),
    ];
  }

  /// Dialog input catatan baru.
  Future<void> _addNote(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Tulis catatanmu'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) plantStore.addNote(plant, text);
  }

  // Bagian 4: Galeri Foto Tanaman
  List<Widget> _photoSection(BuildContext context) {
    return [
      _title(context, 'Foto'),
      const SizedBox(height: 10),
      if (plant.photoPaths.isNotEmpty) ...[
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final path in plant.photoPaths)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.line),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.file(
                        File(path),
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: _takePhoto,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Ambil foto'),
      ),
    ];
  }

  /// Membuka kamera perangkat untuk mengambil foto kondisi tanaman.
  Future<void> _takePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) plantStore.addPhoto(plant, picked.path);
  }

  // Bagian 5: Opsi Hapus Tanaman / Uji Coba
  List<Widget> _dangerSection(BuildContext context) {
    return [
      if (kDebugMode)
        TextButton.icon(
          onPressed: () => plantStore.debugShift(plant, 7),
          icon: const Icon(Icons.fast_forward),
          label: const Text('Uji coba: maju 7 hari'),
        ),
      TextButton.icon(
        onPressed: () => _confirmDead(context),
        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
        label: const Text(
          'Tanaman mati atau tidak layak dirawat',
          style: TextStyle(color: AppColors.danger),
        ),
      ),
    ];
  }

  /// Konfirmasi penghapusan data tanaman secara permanen
  Future<void> _confirmDead(BuildContext context) async {
    final ok = await _confirm(
      context,
      'Hapus tanaman ini?',
      'Data tanaman, catatan, dan fotonya akan dihapus.',
      'Hapus',
    );
    if (ok != true || !context.mounted) return;
    plantStore.remove(plant);
    Navigator.pop(context);
  }

  // Komponen UI Pendukung 
  Widget _title(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: context.ink,
        ),
      );

  /// Kotak informasi ringan dengan latar lembut sesuai tema.
  Widget _info(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.ink, height: 1.4, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Kotak peringatan khusus (panen siap, cabut akar, atau peringatan cuaca).
  Widget _alert(
    BuildContext context,
    IconData icon,
    String title,
    String text, {
    String? action,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.harvest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.harvest.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.ink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: context.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(color: context.ink, height: 1.4, fontSize: 13),
          ),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onTap, child: Text(action)),
          ],
        ],
      ),
    );
  }

  /// Dialog konfirmasi standar dengan tombol Batal dan aksi utama.
  Future<bool?> _confirm(
      BuildContext context, String title, String text, String okLabel) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(okLabel),
          ),
        ],
      ),
    );
  }
}