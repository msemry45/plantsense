import 'package:flutter/material.dart';
import '../../models/plant_image.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class PlantImageCompareScreen extends StatelessWidget {
  final String plantName;
  final PlantImage leftImage;
  final PlantImage rightImage;

  const PlantImageCompareScreen({
    super.key,
    required this.plantName,
    required this.leftImage,
    required this.rightImage,
  });

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  int get _daysBetween {
    final diff = rightImage.capturedAt.difference(leftImage.capturedAt).inDays;
    return diff.abs();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.comparePhotosTitle(plantName)),
        elevation: 0,
        actions: const [
          LanguageToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Growth interval summary banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.lightGreen.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryGreen.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: AppColors.primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.daysGrowthInterval(_daysBetween),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.compareDescription,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Left (Earlier) Photo Card
            _buildPhotoCard(
              context: context,
              label: l10n.earlierPhoto,
              image: leftImage,
              isEarlier: true,
            ),
            const SizedBox(height: 16),

            // Center Comparison divider
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_downward, size: 14, color: AppColors.limeGreen),
                    const SizedBox(width: 6),
                    Text(
                      l10n.daysLater(_daysBetween),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Right (Later) Photo Card
            _buildPhotoCard(
              context: context,
              label: l10n.laterPhoto,
              image: rightImage,
              isEarlier: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required BuildContext context,
    required String label,
    required PlantImage image,
    required bool isEarlier,
  }) {
    final l10n = context.l10n;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightGreen.withAlpha(140)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: isEarlier
                ? AppColors.lightGreen.withAlpha(120)
                : AppColors.primaryGreen.withAlpha(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isEarlier ? Icons.history : Icons.update,
                      size: 16,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(image.capturedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // Proportional Image Viewer
          Container(
            height: 280,
            color: Colors.black12,
            child: image.signedUrl != null
                ? Image.network(
                    image.signedUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.black26),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, size: 48, color: AppColors.primaryGreen),
                  ),
          ),

          // Footer info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.sourcePrefix}${image.source == "camera" ? l10n.cameraSource : l10n.gallerySource}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  image.formattedFileSize,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

