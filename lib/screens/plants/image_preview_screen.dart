import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/plant_image_service.dart';
import '../../services/diagnosis_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final ImageSource? initialSource;
  final PlantImageService? plantImageService;

  const ImagePreviewScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.initialSource,
    this.plantImageService,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late final PlantImageService _imageService;
  late final DiagnosisService _diagnosisService;
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedFile;
  Uint8List? _imageBytes;
  String _source = 'gallery';
  String _mimeType = 'image/jpeg';
  int _fileSizeBytes = 0;

  bool _isLoading = false;
  bool _isUploading = false;
  bool _analyzeImmediately = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _imageService = widget.plantImageService ?? PlantImageService();
    _diagnosisService = DiagnosisService();
    if (widget.initialSource != null) {
      _pickImage(widget.initialSource!);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _validationError = null;
    });

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.split('.').last.toLowerCase();
        String detectedMime = 'image/jpeg';
        if (ext == 'png') {
          detectedMime = 'image/png';
        } else if (ext == 'webp') {
          detectedMime = 'image/webp';
        } else if (ext == 'heic' || ext == 'heif') {
          detectedMime = 'image/heic';
        }

        // Validate size
        String? error;
        if (bytes.isEmpty) {
          error = 'The selected file is empty.';
        } else if (bytes.length > PlantImageService.maxFileSizeBytes) {
          final sizeMb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
          error = 'File size ($sizeMb MB) exceeds the maximum allowed 10 MB limit.';
        } else if (!PlantImageService.allowedMimeTypes.contains(detectedMime)) {
          error = 'Unsupported file format ($detectedMime). Allowed formats: JPEG, PNG, WebP, HEIC.';
        }

        setState(() {
          _selectedFile = picked;
          _imageBytes = bytes;
          _source = source == ImageSource.camera ? 'camera' : 'gallery';
          _mimeType = detectedMime;
          _fileSizeBytes = bytes.length;
          _validationError = error;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _validationError = 'Error accessing image: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _upload() async {
    if (_imageBytes == null || _validationError != null) return;

    setState(() {
      _isUploading = true;
      _validationError = null;
    });

    try {
      final plantImage = await _imageService.uploadPlantImage(
        plantId: widget.plantId,
        imageBytes: _imageBytes!,
        fileName: _selectedFile?.name ?? 'growth_photo.jpg',
        source: _source,
        mimeType: _mimeType,
        capturedAt: DateTime.now(),
      );

      if (_analyzeImmediately) {
        try {
          await _diagnosisService.analyzePlantImage(
            plantId: widget.plantId,
            imageId: plantImage.id,
            language: mounted && context.l10n.isArabic ? 'ar' : 'en',
          );
        } catch (_) {
          // If analysis fails, image is still safely saved
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.photoUploadedSuccess),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop(plantImage);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _validationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String get _formattedSize {
    if (_fileSizeBytes < 1024) return '$_fileSizeBytes B';
    if (_fileSizeBytes < 1024 * 1024) {
      return '${(_fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(_fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addPhotoForPlantTitle(widget.plantName)),
        elevation: 0,
        actions: const [
          LanguageToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Preview Container or Picker Prompt
                  if (_imageBytes != null) ...[
                    Container(
                      height: 320,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _validationError != null
                              ? AppColors.semanticError
                              : AppColors.lightGreen,
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // File metadata badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n.sizePrefix}$_formattedSize • ${_mimeType.toUpperCase().replaceAll('IMAGE/', '')}',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen.withAlpha(150),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${l10n.sourcePrefix}${_source == "camera" ? l10n.cameraSource : l10n.gallerySource}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Empty placeholder prompting selection
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightGreen, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 64,
                            color: AppColors.primaryGreen.withAlpha(180),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.selectGrowthPhotoPrompt,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.maxFileSizeNotice,
                            style: const TextStyle(fontSize: 13, color: Colors.black45),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_validationError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.semanticError.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.semanticError.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.semanticError),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: const TextStyle(
                                color: AppColors.semanticError,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Source selection buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: Text(l10n.cameraSource),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: Text(l10n.gallerySource),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_imageBytes != null && _validationError == null) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.lightGreen.withAlpha(140),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: _analyzeImmediately,
                        onChanged: _isUploading
                            ? null
                            : (val) => setState(
                                  () => _analyzeImmediately = val ?? false,
                                ),
                        activeColor: AppColors.primary,
                        title: Text(
                          l10n.analyzeNowCheckboxPrompt,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dark,
                          ),
                        ),
                        secondary: const Icon(
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _upload,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(_isUploading ? l10n.uploadingPhoto : l10n.confirmAndUploadButton),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
