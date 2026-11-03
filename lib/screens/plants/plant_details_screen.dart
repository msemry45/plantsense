import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/plant.dart';
import '../../models/species.dart';
import '../../models/plant_image.dart';
import '../../models/observation_note.dart';
import '../../models/diagnosis.dart';
import '../../services/plant_service.dart';
import '../../services/plant_image_service.dart';
import '../../services/observation_note_service.dart';
import '../../services/diagnosis_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';
import 'diagnosis_result_screen.dart';
import 'diagnosis_history_screen.dart';

class PlantDetailsScreen extends StatefulWidget {
  final String plantId;
  final PlantService? plantService;
  final PlantImageService? plantImageService;
  final ObservationNoteService? noteService;
  final AuthService? authService;
  final DiagnosisService? diagnosisService;

  const PlantDetailsScreen({
    super.key,
    required this.plantId,
    this.plantService,
    this.plantImageService,
    this.noteService,
    this.authService,
    this.diagnosisService,
  });

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  late final PlantService _plantService;
  late final PlantImageService _imageService;
  late final ObservationNoteService _noteService;
  late final DiagnosisService _diagnosisService;
  late final AuthService _authService;

  Plant? _plant;
  List<PlantImage> _recentImages = [];
  List<ObservationNote> _recentNotes = [];
  Diagnosis? _latestDiagnosis;
  bool _isAnalyzingLeaf = false;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _plantService = widget.plantService ?? PlantService();
    _imageService = widget.plantImageService ?? PlantImageService();
    _noteService = widget.noteService ?? ObservationNoteService();
    _diagnosisService = widget.diagnosisService ?? DiagnosisService();
    _authService = widget.authService ?? AuthService();
    _loadPlantData();
  }

  Future<void> _loadPlantData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plant = await _plantService.getPlantById(widget.plantId);
      if (plant == null) {
        setState(() {
          _errorMessage = 'Plant not found.';
          _isLoading = false;
        });
        return;
      }

      final images = await _imageService.getPlantImages(widget.plantId);
      final notes = await _noteService.getNotes(widget.plantId);
      Diagnosis? diagnosis;
      try {
        diagnosis = await _diagnosisService.getLatestDiagnosis(widget.plantId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _plant = plant;
          _recentImages = images;
          _recentNotes = notes;
          _latestDiagnosis = diagnosis;
          _isLoading = false;
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

  bool get _canMutate {
    final role = _authService.currentUserProfile?.role;
    return role == 'farmer' || role == 'admin';
  }

  Future<void> _confirmDeletePlant() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePlantTitle),
        content: Text(l10n.deletePlantContent(_plant?.name ?? '')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.semanticError),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _plantService.deletePlant(widget.plantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.plantDeletedSuccess),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
          context.pop(true);
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plantDetailsTitle)),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    if (_errorMessage != null || _plant == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plantDetailsTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 52, color: AppColors.semanticError),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? l10n.plantNotFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadPlantData,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final plant = _plant!;
    final latestImage = _recentImages.isNotEmpty ? _recentImages.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        elevation: 0,
        actions: [
          const LanguageToggleButton(),
          const SizedBox(width: 4),
          if (_canMutate) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.edit,
              onPressed: () async {
                final updated = await context.push<bool>('/plants/${plant.id}/edit');
                if (updated == true) {
                  _loadPlantData();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: _confirmDeletePlant,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadPlantData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: _loadPlantData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Image / Cover
              _buildCoverImage(latestImage),
              const SizedBox(height: 16),

              // Title and Species Card
              _buildTitleCard(plant),
              const SizedBox(height: 16),

              // Action Buttons Row (Add Photo, Photo Timeline, Notes)
              _buildActionButtons(plant),
              const SizedBox(height: 20),

              // Care & Growth Conditions Card (if species data exists)
              if (plant.species != null) ...[
                _buildCareConditionsCard(plant.species!),
                const SizedBox(height: 20),
              ],

              // Photos Timeline Section
              _buildPhotosSection(plant),
              const SizedBox(height: 20),

              // Observation Notes Section
              _buildNotesSection(plant),
              const SizedBox(height: 20),

              // AI Plant Leaf Condition Analysis (Milestone 4)
              _buildAIDiagnosisCard(plant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(PlantImage? latestImage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.lightGreen.withAlpha(100),
          border: Border.all(color: AppColors.lightGreen.withAlpha(140)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (latestImage?.signedUrl != null)
              Image.network(
                latestImage!.signedUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.local_florist, size: 72, color: AppColors.primaryGreen),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_florist_outlined,
                      size: 64,
                      color: AppColors.primaryGreen.withAlpha(160),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.noPhotoUploadedYet,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Top-right badge
            if (latestImage != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${context.l10n.isArabic ? "الأحدث:" : "Latest:"} ${latestImage.capturedAt.year}-${latestImage.capturedAt.month.toString().padLeft(2, '0')}-${latestImage.capturedAt.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard(Plant plant) {
    final l10n = context.l10n;
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightGreen.withAlpha(140)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plant.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.dark,
                        ),
                      ),
                      if (plant.species != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          plant.species!.commonName +
                              (plant.species!.scientificName != null
                                  ? ' (${plant.species!.scientificName})'
                                  : ''),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: plant.status == 'active'
                        ? AppColors.lightGreen.withAlpha(180)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    plant.status == 'active' ? l10n.activeStatus : plant.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: plant.status == 'active' ? AppColors.primaryGreen : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Metadata Grid (Location, Planted On, Age)
            Row(
              children: [
                _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  label: l10n.locationLabel.replaceAll(' *', ''),
                  value: plant.location ?? l10n.notSpecified,
                ),
                _buildInfoTile(
                  icon: Icons.calendar_today_outlined,
                  label: l10n.plantedDateLabel,
                  value: plant.plantedOn != null
                      ? '${plant.plantedOn!.year}-${plant.plantedOn!.month.toString().padLeft(2, '0')}-${plant.plantedOn!.day.toString().padLeft(2, '0')}'
                      : l10n.unknown,
                ),
                _buildInfoTile(
                  icon: Icons.timelapse,
                  label: l10n.plantAgeLabel,
                  value: plant.daysSincePlanted != null
                      ? l10n.daysOld(plant.daysSincePlanted!)
                      : 'N/A',
                ),
              ],
            ),

            if (plant.notes != null && plant.notes!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plant.notes!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Plant plant) {
    final l10n = context.l10n;
    return Row(
      children: [
        if (_canMutate)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final added = await context.push(
                  '/plants/${plant.id}/image-preview',
                  extra: {'plantName': plant.name},
                );
                if (added != null) {
                  _loadPlantData();
                }
              },
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: Text(l10n.addPhoto),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (_canMutate) const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push(
                '/plants/${plant.id}/images',
                extra: {'plantName': plant.name},
              );
            },
            icon: const Icon(Icons.photo_library, size: 18),
            label: Text(l10n.photoHistoryWithCount(_recentImages.length)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareConditionsCard(Species species) {
    final l10n = context.l10n;
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightGreen.withAlpha(140)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.thermostat_outlined, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.speciesCareGuidelines,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (species.idealTemperatureMin != null || species.idealTemperatureMax != null)
              _buildConditionRow(
                Icons.wb_sunny_outlined,
                l10n.idealTemperature,
                '${species.idealTemperatureMin?.toStringAsFixed(0) ?? '?'}°C – ${species.idealTemperatureMax?.toStringAsFixed(0) ?? '?'}°C',
              ),
            if (species.idealHumidityMin != null || species.idealHumidityMax != null)
              _buildConditionRow(
                Icons.water_drop_outlined,
                l10n.idealHumidity,
                '${species.idealHumidityMin?.toStringAsFixed(0) ?? '?'}% – ${species.idealHumidityMax?.toStringAsFixed(0) ?? '?'}%',
              ),
            if (species.idealLightConditions != null)
              _buildConditionRow(
                Icons.light_mode_outlined,
                l10n.lightConditions,
                _localizeLightConditions(species.idealLightConditions!, l10n.isArabic),
              ),
            if (species.careInstructions != null) ...[
              const SizedBox(height: 8),
              Text(
                _localizeCareInstructions(species.careInstructions!, l10n.isArabic),
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _localizeLightConditions(String light, bool isArabic) {
    if (!isArabic) return light;
    final lower = light.toLowerCase();
    if (lower.contains('full sun') || lower.contains('direct')) {
      return 'شمس مباشرة / ساطعة ($light)';
    } else if (lower.contains('partial') || lower.contains('semi')) {
      return 'ظل جزئي ($light)';
    } else if (lower.contains('indirect')) {
      return 'ضوء غير مباشر ($light)';
    } else if (lower.contains('low light')) {
      return 'إضاءة منخفضة ($light)';
    }
    return light;
  }

  String _localizeCareInstructions(String text, bool isArabic) {
    if (!isArabic) return text;
    final lower = text.toLowerCase();
    if (lower.contains('moist') || lower.contains('water regularly')) {
      return 'الحفاظ على رطوبة التربة بانتظام وضمان تصريف جيد، مع تجنب ري الأوراق مباشرة.';
    }
    return text;
  }

  Widget _buildConditionRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black45),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.dark),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(Plant plant) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.growthPhotosSection(_recentImages.length),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_recentImages.isNotEmpty)
              TextButton(
                onPressed: () {
                  context.push(
                    '/plants/${plant.id}/images',
                    extra: {'plantName': plant.name},
                  );
                },
                child: Text(l10n.viewAll),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentImages.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGreen.withAlpha(120)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primaryGreen, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.isArabic ? 'لا توجد صور نمو بعد' : 'No growth photos yet',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.isArabic
                            ? 'التقط أو ارفع صورة لبدء المتابعة البصرية.'
                            : 'Take or upload a photo to start visual tracking.',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recentImages.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final img = _recentImages[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 110,
                    height: 110,
                    color: Colors.black12,
                    child: img.signedUrl != null
                        ? Image.network(
                            img.signedUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          )
                        : const Icon(Icons.image),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNotesSection(Plant plant) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.observationNotesSection(_recentNotes.length),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.dark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push(
                  '/plants/${plant.id}/notes',
                  extra: {'plantName': plant.name},
                );
              },
              child: Text(l10n.viewAllOrAdd),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentNotes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGreen.withAlpha(120)),
            ),
            child: Row(
              children: [
                const Icon(Icons.note_alt_outlined, color: AppColors.primaryGreen, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noNotesRecorded,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.recordGrowthNotesAdvice,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ..._recentNotes.take(2).map((note) {
            return Card(
              elevation: 0.5,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.lightGreen.withAlpha(120)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${note.observedAt.year}-${note.observedAt.month.toString().padLeft(2, '0')}-${note.observedAt.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.note,
                      style: const TextStyle(fontSize: 13, color: AppColors.dark),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _triggerLeafAnalysis(Plant plant) async {
    final l10n = context.l10n;
    if (_recentImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoRequiredForAIAnalysis),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: l10n.addPhoto,
            textColor: Colors.white,
            onPressed: () async {
              final result = await context.push(
                '/plants/${plant.id}/image-preview',
                extra: {'plantName': plant.name},
              );
              if (result != null) _loadPlantData();
            },
          ),
        ),
      );
      return;
    }

    final targetImage = _recentImages.first;

    setState(() => _isAnalyzingLeaf = true);

    // Show progressive dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.analyzingLeafProgress,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.analyzingLeafWait,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.dark.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final diag = await _diagnosisService.analyzePlantImage(
        plantId: plant.id,
        imageId: targetImage.id,
        speciesCommon: plant.species?.commonName,
        speciesScientific: plant.species?.scientificName,
        language: l10n.isArabic ? 'ar' : 'en',
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss loading dialog
        setState(() {
          _latestDiagnosis = diag;
        });

        // Open full result screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DiagnosisResultScreen(
              plantName: plant.name,
              diagnosis: diag,
              imageUrl: targetImage.signedUrl,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(
              '${l10n.aiAnalysisFailedMessage}\n${e.toString().replaceFirst("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingLeaf = false);
      }
    }
  }

  Widget _buildAIDiagnosisCard(Plant plant) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;
    final diag = _latestDiagnosis;

    Color statusBg;
    Color statusFg;
    if (diag != null) {
      if (diag.isHealthy) {
        statusBg = const Color(0xFFE2F3E7);
        statusFg = AppColors.primary;
      } else if (diag.isUncertain) {
        statusBg = const Color(0xFFECEFF1);
        statusFg = const Color(0xFF455A64);
      } else {
        statusBg = const Color(0xFFFFF3E0);
        statusFg = const Color(0xFFE65100);
      }
    } else {
      statusBg = AppColors.lightGreen.withAlpha(90);
      statusFg = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGreen.withAlpha(140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiDiagnosisNoticeTitle,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      l10n.aiDiagnosisNoticeBody,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.dark.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (diag != null)
                IconButton(
                  tooltip: l10n.viewHistoryAction,
                  icon: const Icon(Icons.history, color: AppColors.primary),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DiagnosisHistoryScreen(
                          plantId: plant.id,
                          plantName: plant.name,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (diag != null) ...[
            // Result Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusFg.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    diag.isHealthy
                        ? Icons.check_circle_outline
                        : diag.isUncertain
                            ? Icons.help_outline
                            : Icons.warning_amber_rounded,
                    color: statusFg,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.healthStatusLabel}: ${diag.localizedStatus(isArabic)}',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusFg,
                          ),
                        ),
                        Text(
                          '${l10n.severityLabel}: ${diag.localizedSeverity(isArabic)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusFg.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (diag.isCached) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isArabic ? 'سابق' : 'Cached',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusFg.withOpacity(0.2)),
                    ),
                    child: Text(
                      diag.rawResponse?['request_language'] == 'en'
                          ? (isArabic ? 'اللغة: EN' : 'Lang: EN')
                          : (isArabic ? 'اللغة: عربي' : 'Lang: AR'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (diag.visibleSigns.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: diag.visibleSigns.take(4).map((sign) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withAlpha(120),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sign,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (diag.summary != null && diag.summary!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                diag.summary!,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.dark.withOpacity(0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DiagnosisResultScreen(
                            plantName: plant.name,
                            diagnosis: diag,
                            imageUrl: _recentImages.isNotEmpty
                                ? _recentImages.first.signedUrl
                                : null,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: Text(l10n.viewFullReportAction),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_canMutate) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isAnalyzingLeaf ? null : () => _triggerLeafAnalysis(plant),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(l10n.reanalyzeAction),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            // Empty / unanalyzed state
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.startFirstAnalysisPrompt,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  color: AppColors.dark.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_canMutate)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzingLeaf
                      ? null
                      : () => _triggerLeafAnalysis(plant),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_recentImages.isNotEmpty
                      ? l10n.analyzeLatestPhotoAction
                      : l10n.addPhoto),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
