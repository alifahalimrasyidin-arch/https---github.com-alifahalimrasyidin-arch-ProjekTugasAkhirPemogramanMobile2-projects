import 'package:flutter/foundation.dart';
import '../models/care_rules.dart';
import '../models/plant.dart';

/// Catatan panen, nanti dipakai untuk statistik dan Rekap.
class HarvestRecord {
  final String name;
  final String type;
  final PlantCategory category;
  final DateTime at;
  final String how; // cara panen: panen potong, cabut akar, atau petik buah
  HarvestRecord(this.name, this.type, this.category, this.how)
      : at = DateTime.now();
}

/// Menyimpan daftar tanaman milik user.
/// Setiap kali data berubah, layar yang mendengarkan ikut diperbarui.
class PlantStore extends ChangeNotifier {
  final List<Plant> _plants = [];
  final List<HarvestRecord> _harvests = [];
  final List<DateTime> _activity = []; // waktu setiap aksi perawatan
  int _totalAdded = 0;

  List<Plant> get plants => List.unmodifiable(_plants);
  List<HarvestRecord> get harvests => List.unmodifiable(_harvests);

  // Statistik untuk beranda dan Rekap
  int get totalPlantsEver => _totalAdded;
  int get totalCareActions => _activity.length;
  int get totalHarvests => _harvests.length;

  /// Jumlah aksi perawatan pada satu hari.
  int activityOn(DateTime day) => _activity
      .where((d) => d.year == day.year && d.month == day.month && d.day == day.day)
      .length;

  void add(Plant plant) {
    final r = careRulesOf(plant.careType);
    if (r != null && r.hasSemai) plant.withSemai = true;
    plant.stage = plant.withSemai ? PlantStage.semai : PlantStage.tumbuh;
    plant.stageStart = plant.plantedAt;
    _plants.add(plant);
    _totalAdded++;
    notifyListeners();
  }

  void logCare(Plant plant, CareKind kind) {
    plant.logs.add(CareLog(kind));
    _activity.add(DateTime.now());
    notifyListeners();
  }

  /// Dipakai saat user pindah tanah, atau melewati masa semai.
  void startGrowing(Plant plant) {
    plant.stage = PlantStage.tumbuh;
    plant.stageStart = DateTime.now();
    notifyListeners();
  }

  /// Panen potong: tanaman tumbuh lagi, siklus berulang.
  void harvestCut(Plant plant) {
    plant.cutCount++;
    plant.lastCutAt = DateTime.now();
    plant.logs.add(CareLog(CareKind.panenPotong));
    _activity.add(DateTime.now());
    _harvests
        .add(HarvestRecord(plant.name, plant.type, plant.category, 'panen potong'));
    notifyListeners();
  }

  /// Tanaman buah: mencatat satu kali petik buah (bisa berkali-kali).
  void pickFruit(Plant plant) {
    plant.logs.add(CareLog(CareKind.petikBuah));
    _activity.add(DateTime.now());
    _harvests
        .add(HarvestRecord(plant.name, plant.type, plant.category, 'petik buah'));
    notifyListeners();
  }

  /// Panen cabut akar: panen berhasil, card tanaman dihapus.
  void harvestPull(Plant plant) {
    _harvests.add(HarvestRecord(plant.name, plant.type, plant.category, 'cabut akar'));
    _activity.add(DateTime.now());
    _plants.remove(plant);
    notifyListeners();
  }

  /// Tanaman mati atau tidak layak dirawat: datanya dihapus.
  void remove(Plant plant) {
    _plants.remove(plant);
    notifyListeners();
  }

  void addNote(Plant plant, String text) {
    plant.notes.add(PlantNote(text));
    notifyListeners();
  }

  void addPhoto(Plant plant, String path) {
    plant.photoPaths.add(path);
    notifyListeners();
  }

  /// Hanya untuk uji coba: memajukan waktu tanaman.
  void debugShift(Plant plant, int days) {
    final d = Duration(days: days);
    plant.stageStart = plant.stageStart.subtract(d);
    if (plant.lastCutAt != null) {
      plant.lastCutAt = plant.lastCutAt!.subtract(d);
    }
    final shifted =
        plant.logs.map((l) => CareLog(l.kind, l.at.subtract(d))).toList();
    plant.logs
      ..clear()
      ..addAll(shifted);
    notifyListeners();
  }
}

/// Satu objek yang dipakai bersama oleh seluruh aplikasi.
final plantStore = PlantStore();