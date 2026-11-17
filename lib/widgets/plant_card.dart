import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../screens/plant_detail_page.dart';

/// Card satu tanaman. Warnanya mengikuti kategori:
/// hijau (sayur dan buah), merah (tanaman hias), biru (hidroponik).
/// Kalau ditekan, membuka halaman detail tanaman.
class PlantCard extends StatelessWidget {
  final Plant plant;
  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final day = DateTime.now().difference(plant.plantedAt).inDays + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: plant.category.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDetailPage(plant: plant),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(plant.category.icon, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plant.type}, ${plant.category.label}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      if (plant.careType != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            plant.careType!.label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  plant.stage == PlantStage.semai ? 'Semai' : 'Hari ke-$day',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}