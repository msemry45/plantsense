import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/plant_image.dart';
import '../../services/plant_image_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class PlantImagesTimelineScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final PlantImageService? plantImageService;

  const PlantImagesTimelineScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.plantImageService,
  });

  @override
  State<PlantImagesTimelineScreen> createState() => _PlantImagesTimelineScreenState();
}

class _PlantImagesTimelineScreenState extends State<PlantImagesTimelineScreen> {
  late final PlantImageService _imageService;

  List<PlantImage> _images = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Comparison selection mode
  bool _compareMode = false;
  final Set<String> _selectedImageIds = {};

  @override
  void initState() {
    super.initState();
    _imageService = widget.plantImageService ?? PlantImageService();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final images = await _imageService.getPlantImages(widget.plantId);
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
          _selectedImageIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelectImage(String id) {
    setState(() {
      if (_selectedImageIds.contains(id)) {
        _selectedImageIds.remove(id);
      } else {
        if (_selectedImageIds.length >= 2) {
          // Keep at most 2 for comparison
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.exactlyTwoPhotosWarning),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedImageIds.add(id);
      }
    });
  }

  void _openCompare() {
    if (_selectedImageIds.length != 2) return;
    final selected = _images.where((img) => _selectedImageIds.contains(img.id)).toList();
    if (selected.length == 2) {
      // Sort chronologically: older on left, newer on right
      selected.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
      context.push(
        '/plants/${widget.plantId}/compare',
        extra: {
          'plantName': widget.plantName,
          'leftImage': selected[0],
          'rightImage': selected[1],
        },
      );
    }
  }

  void _showImageDialog(PlantImage image) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 480),
                  color: Colors.black,
                  child: image.signedUrl != null
                      ? Image.network(
                          image.signedUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : const Center(child: CircularProgressIndicator(color: Colors.white)),
                        )
                      : const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${image.capturedAt.year}-${image.capturedAt.month.toString().padLeft(2, '0')}-${image.capturedAt.day.toString().padLeft(2, '0')} ${image.capturedAt.hour.toString().padLeft(2, '0')}:${image.capturedAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      '${image.source.toUpperCase()} • ${image.formattedFileSize}',
                      style: const TextStyle(color: AppColors.limeGreen, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 28),
                    tooltip: l10n.deletePhotoTitle,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.deletePhotoTitle),
                          content: Text(l10n.deletePhotoConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: TextButton.styleFrom(foregroundColor: AppColors.semanticError),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        Navigator.of(dialogCtx).pop(); // close image dialog
                        try {
                          await _imageService.deletePlantImage(image);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.photoDeletedSuccess),
                                backgroundColor: AppColors.primaryGreen,
                              ),
                            );
                            _loadImages();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: AppColors.semanticError,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.photoHistoryTitle(widget.plantName)),
        elevation: 0,
        actions: [
          const LanguageToggleButton(),
          const SizedBox(width: 4),
          if (_images.length >= 2)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _compareMode = !_compareMode;
                  _selectedImageIds.clear();
                });
              },
              icon: Icon(
                _compareMode ? Icons.check : Icons.compare,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _compareMode ? l10n.exitCompareMode : l10n.compareMode,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadImages,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _compareMode && _selectedImageIds.length == 2
          ? FloatingActionButton.extended(
              onPressed: _openCompare,
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.compare_arrows),
              label: Text(
                l10n.compareSelectedButton,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () async {
                final added = await context.push(
                  '/plants/${widget.plantId}/image-preview',
                  extra: {'plantName': widget.plantName},
                );
                if (added != null) {
                  _loadImages();
                }
              },
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo),
              label: Text(l10n.addPhoto, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.semanticError),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadImages,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = context.l10n;

    if (_images.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  size: 44,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.isArabic ? 'لا توجد صور نمو بعد' : 'No growth photos yet',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.isArabic
                    ? 'التقط صوراً دورية لإنشاء سجل زمني لتطور نمو نبتتك ومقارنتها عبر الأيام.'
                    : 'Capture photos regularly to create a dated visual timeline of your plant’s growth and compare changes over time.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final added = await context.push(
                    '/plants/${widget.plantId}/image-preview',
                    extra: {'plantName': widget.plantName},
                  );
                  if (added != null) {
                    _loadImages();
                  }
                },
                icon: const Icon(Icons.add_a_photo),
                label: Text(l10n.takeFirstPhoto),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_compareMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.lightGreen.withAlpha(180),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedImageIds.length == 2
                        ? l10n.selectTwoPhotosForCompare
                        : l10n.selectPhotosToCompare(_selectedImageIds.length),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: _loadImages,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final image = _images[index];
                final isSelected = _selectedImageIds.contains(image.id);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (_compareMode) {
                      _toggleSelectImage(image.id);
                    } else {
                      _showImageDialog(image);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.lightGreen.withAlpha(120),
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Box
                            Expanded(
                              child: image.signedUrl != null
                                  ? Image.network(
                                      image.signedUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image, color: Colors.black26),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.lightGreen.withAlpha(80),
                                      child: const Center(
                                        child: Icon(Icons.image, color: AppColors.primaryGreen),
                                      ),
                                    ),
                            ),

                            // Caption & Date
                            Container(
                              padding: const EdgeInsets.all(8),
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${image.capturedAt.year}-${image.capturedAt.month.toString().padLeft(2, '0')}-${image.capturedAt.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        image.source.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      Text(
                                        image.formattedFileSize,
                                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Selection Checkbox Badge in Compare Mode
                        if (_compareMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primaryGreen : Colors.white70,
                                border: Border.all(
                                  color: isSelected ? Colors.white : AppColors.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

