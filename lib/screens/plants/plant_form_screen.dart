import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/species.dart';
import '../../services/plant_service.dart';
import '../../services/species_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_toggle_button.dart';

class PlantFormScreen extends StatefulWidget {
  final String? plantId;
  final PlantService? plantService;
  final SpeciesService? speciesService;

  const PlantFormScreen({
    super.key,
    this.plantId,
    this.plantService,
    this.speciesService,
  });

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final PlantService _plantService;
  late final SpeciesService _speciesService;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedSpeciesId;
  DateTime? _selectedPlantedDate;
  String _status = 'active';

  List<Species> _speciesList = [];
  bool _isLoadingInitial = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get isEdit => widget.plantId != null;

  @override
  void initState() {
    super.initState();
    _plantService = widget.plantService ?? PlantService();
    _speciesService = widget.speciesService ?? SpeciesService();
    _selectedPlantedDate = DateTime.now();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
    });

    try {
      final species = await _speciesService.getPublishedSpecies();
      _speciesList = species;

      if (isEdit) {
        final plant = await _plantService.getPlantById(widget.plantId!);
        if (plant != null) {
          _nameController.text = plant.name;
          _locationController.text = plant.location ?? '';
          _notesController.text = plant.notes ?? '';
          _selectedSpeciesId = plant.speciesId;
          _selectedPlantedDate = plant.plantedOn;
          _status = plant.status;
        } else {
          _errorMessage = 'Plant not found.';
        }
      }

      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<void> _pickPlantedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPlantedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.dark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedPlantedDate = picked);
    }
  }

  Future<void> _showAddCustomSpeciesDialog() async {
    final l10n = context.l10n;
    final commonNameCtrl = TextEditingController();
    final scientificNameCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isAdding = false;
    String? dialogError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.isArabic ? 'إضافة نوع زراعي جديد' : 'Add Custom Species',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (dialogError != null) ...[
                      Text(
                        dialogError!,
                        style: const TextStyle(color: AppColors.semanticError, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: commonNameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.isArabic ? 'اسم النوع الشائع *' : 'Common Name *',
                        hintText: l10n.isArabic ? 'مثال: نعناع بري، فراولة' : 'e.g. Wild Mint, Strawberry',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.isArabic ? 'يرجى كتابة اسم النوع' : 'Please enter species name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: scientificNameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.isArabic ? 'الاسم العلمي (اختياري)' : 'Scientific Name (optional)',
                        hintText: 'e.g. Mentha arvensis',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding ? null : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isAdding = true;
                            dialogError = null;
                          });

                          try {
                            final newSpecies = await _speciesService.createCustomSpecies(
                              commonNameCtrl.text.trim(),
                              scientificName: scientificNameCtrl.text.trim(),
                            );

                            if (mounted) {
                              setState(() {
                                if (!_speciesList.any((s) => s.id == newSpecies.id)) {
                                  _speciesList.add(newSpecies);
                                }
                                _selectedSpeciesId = newSpecies.id;
                              });

                              Navigator.of(ctx).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.isArabic
                                        ? 'تمت إضافة النوع "${newSpecies.commonName}" واختياره بنجاح'
                                        : 'Species "${newSpecies.commonName}" added and selected',
                                  ),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isAdding = false;
                              dialogError = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.isArabic ? 'إضافة وتحديد' : 'Add & Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (isEdit) {
        await _plantService.updatePlant(
          id: widget.plantId!,
          name: _nameController.text.trim(),
          speciesId: _selectedSpeciesId,
          location: _locationController.text.trim(),
          plantedOn: _selectedPlantedDate,
          notes: _notesController.text.trim(),
          status: _status,
        );
      } else {
        await _plantService.createPlant(
          name: _nameController.text.trim(),
          speciesId: _selectedSpeciesId,
          location: _locationController.text.trim(),
          plantedOn: _selectedPlantedDate,
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? l10n.plantUpdatedSuccess : l10n.plantSavedSuccess),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.plantFormEditTitle : l10n.plantFormAddTitle),
        elevation: 0,
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: _isLoadingInitial
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.semanticError.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.semanticError.withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.semanticError),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.semanticError, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Plant Name Field
                    Text(
                      l10n.plantNameLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: l10n.plantNameHint,
                        prefixIcon: const Icon(Icons.eco, color: AppColors.primaryGreen),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.isArabic
                              ? 'يرجى إدخال اسم للنبات.'
                              : 'Please enter a name for the plant.';
                        }
                        if (value.trim().length > 100) {
                          return l10n.isArabic
                              ? 'اسم النبات لا يمكن أن يتجاوز 100 حرف.'
                              : 'Plant name cannot exceed 100 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Species Header Row with Manual Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.speciesLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: _showAddCustomSpeciesDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            l10n.isArabic ? 'إضافة نوع يدوياً' : 'Add custom species',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _selectedSpeciesId,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category, color: AppColors.primaryGreen),
                        hintText: l10n.selectSpeciesHint,
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            l10n.isArabic ? 'مخصص / غير محدد' : 'Custom / Not Specified',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                        ..._speciesList.map((species) {
                          return DropdownMenuItem<String?>(
                            value: species.id,
                            child: Text(
                              '${species.commonName}${species.scientificName != null ? ' (${species.scientificName})' : ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        DropdownMenuItem<String?>(
                          value: '__add_custom_species__',
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle, color: AppColors.primaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                l10n.isArabic ? '+ إضافة نوع زراعي جديد يدوياً...' : '+ Add new species manually...',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__add_custom_species__') {
                          _showAddCustomSpeciesDialog();
                        } else {
                          setState(() => _selectedSpeciesId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Planting Date Picker Row
                    Text(
                      l10n.plantedDateLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickPlantedDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedPlantedDate != null
                                  ? '${_selectedPlantedDate!.year}-${_selectedPlantedDate!.month.toString().padLeft(2, '0')}-${_selectedPlantedDate!.day.toString().padLeft(2, '0')}'
                                  : (l10n.isArabic ? 'اختر تاريخ الزراعة' : 'Select date planted'),
                              style: TextStyle(
                                fontSize: 15,
                                color: _selectedPlantedDate != null ? AppColors.dark : Colors.black45,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: Colors.black45),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Field
                    Text(
                      l10n.locationLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: l10n.locationHint,
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    Text(
                      l10n.notesLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.notesHint,
                        alignLabelWithHint: true,
                      ),
                    ),

                    if (isEdit) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.isArabic ? 'الحالة' : 'Status',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'active',
                            label: Text(l10n.activeStatus),
                          ),
                          ButtonSegment(
                            value: 'archived',
                            label: Text(l10n.isArabic ? 'مؤرشف' : 'Archived'),
                          ),
                        ],
                        selected: {_status},
                        onSelectionChanged: (set) {
                          setState(() => _status = set.first);
                        },
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(isEdit
                              ? (l10n.isArabic ? 'حفظ التعديلات' : 'Save Changes')
                              : (l10n.isArabic ? 'إضافة النبات' : 'Create Plant')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
