import 'package:flutter/material.dart';
import '../../models/species.dart';
import '../../services/species_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class AdminSpeciesScreen extends StatefulWidget {
  final SpeciesService? speciesService;

  const AdminSpeciesScreen({super.key, this.speciesService});

  @override
  State<AdminSpeciesScreen> createState() => _AdminSpeciesScreenState();
}

class _AdminSpeciesScreenState extends State<AdminSpeciesScreen> {
  late final SpeciesService _speciesService;
  final TextEditingController _searchController = TextEditingController();

  List<Species> _speciesList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _speciesService = widget.speciesService ?? SpeciesService();
    _loadSpecies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecies({String? query}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _speciesService.getAllSpeciesForAdmin(search: query);
      if (mounted) {
        setState(() {
          _speciesList = list;
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

  Future<void> _togglePublish(Species species, bool newValue) async {
    try {
      final updated = await _speciesService.toggleSpeciesPublished(species.id, newValue);
      if (mounted) {
        setState(() {
          final idx = _speciesList.indexWhere((s) => s.id == species.id);
          if (idx != -1) {
            _speciesList[idx] = updated;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              newValue
                  ? (context.l10n.isArabic
                      ? 'تم نشر "${species.commonName}" في الموسوعة.'
                      : '"${species.commonName}" published to encyclopedia.')
                  : (context.l10n.isArabic
                      ? 'تم إلغاء نشر "${species.commonName}" من الموسوعة.'
                      : '"${species.commonName}" unpublished from encyclopedia.'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteSpecies(Species species) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.isArabic ? 'حذف من الموسوعة' : 'Delete Species'),
        content: Text(
          l10n.isArabic
              ? 'هل أنت متأكد من حذف نبتة "${species.commonName}" نهائياً من الموسوعة؟'
              : 'Are you sure you want to permanently delete "${species.commonName}" from the encyclopedia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _speciesService.deleteSpecies(species.id);
        if (mounted) {
          setState(() {
            _speciesList.removeWhere((s) => s.id == species.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.primary,
              content: Text(
                l10n.isArabic
                    ? 'تم حذف النبتة من الموسوعة بنجاح.'
                    : 'Species deleted successfully from encyclopedia.',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  void _showAddSpeciesDialog() {
    final l10n = context.l10n;
    final commonNameCtrl = TextEditingController();
    final scientificCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final careCtrl = TextEditingController();
    final sourceUrlCtrl = TextEditingController();
    final imagePathCtrl = TextEditingController();
    final tempMinCtrl = TextEditingController();
    final tempMaxCtrl = TextEditingController();
    final humMinCtrl = TextEditingController();
    final humMaxCtrl = TextEditingController();
    final lightCtrl = TextEditingController();
    bool isPublished = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.isArabic ? 'إضافة نبتة يدوياً للموسوعة' : 'Add Species to Encyclopedia'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: commonNameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.isArabic ? 'الاسم الشائع *' : 'Common Name *',
                      hintText: l10n.isArabic ? 'مثال: نعناع بري' : 'e.g. Wild Mint',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: scientificCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.isArabic ? 'الاسم العلمي' : 'Scientific Name',
                      hintText: 'e.g. Mentha arvensis',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.isArabic ? 'الملخص والوصف (ويكيبيديا)' : 'Description / Summary',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: careCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.careGuidelines,
                      hintText: l10n.isArabic ? 'إرشادات الري والإضاءة' : 'Watering and lighting tips',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sourceUrlCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.isArabic ? 'رابط ويكيبيديا' : 'Wikipedia URL',
                      hintText: 'https://en.wikipedia.org/wiki/...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imagePathCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.isArabic ? 'رابط صورة النبتة (ويكيميديا)' : 'Image URL (Wikimedia)',
                      hintText: 'https://upload.wikimedia.org/...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tempMinCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Min Temp °C'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: tempMaxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Max Temp °C'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: humMinCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Min Hum %'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: humMaxCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Max Hum %'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: lightCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.isArabic ? 'ظروف الإضاءة' : 'Light Conditions',
                      hintText: 'Full sun / Partial shade',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(l10n.isArabic ? 'نشر فوري في الموسوعة' : 'Publish immediately'),
                    value: isPublished,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => isPublished = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = commonNameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(l10n.isArabic ? 'يرجى إدخال اسم النبتة' : 'Please enter species name'),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  final newSpecies = await _speciesService.createSpecies(
                    commonName: name,
                    scientificName: scientificCtrl.text.trim().isEmpty ? null : scientificCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    careInstructions: careCtrl.text.trim().isEmpty ? null : careCtrl.text.trim(),
                    sourceUrl: sourceUrlCtrl.text.trim().isEmpty ? null : sourceUrlCtrl.text.trim(),
                    imagePath: imagePathCtrl.text.trim().isEmpty ? null : imagePathCtrl.text.trim(),
                    license: 'CC BY-SA 4.0',
                    attribution: 'Wikimedia Commons / Wikipedia contributors',
                    idealTemperatureMin: num.tryParse(tempMinCtrl.text),
                    idealTemperatureMax: num.tryParse(tempMaxCtrl.text),
                    idealHumidityMin: num.tryParse(humMinCtrl.text),
                    idealHumidityMax: num.tryParse(humMaxCtrl.text),
                    idealLightConditions: lightCtrl.text.trim().isEmpty ? null : lightCtrl.text.trim(),
                    isPublished: isPublished,
                  );
                  if (mounted) {
                    setState(() {
                      _speciesList.insert(0, newSpecies);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Text(
                          l10n.isArabic ? 'تمت إضافة النبتة للموسوعة بنجاح' : 'Species added successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSpeciesDialog(Species species) {
    final l10n = context.l10n;
    final commonNameCtrl = TextEditingController(text: species.commonName);
    final scientificCtrl = TextEditingController(text: species.scientificName ?? '');
    final descCtrl = TextEditingController(text: species.description ?? '');
    final careCtrl = TextEditingController(text: species.careInstructions ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.isArabic ? 'تعديل بيانات النوع' : 'Edit Species Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commonNameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.isArabic ? 'الاسم الشائع' : 'Common Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scientificCtrl,
                decoration: InputDecoration(
                  labelText: l10n.isArabic ? 'الاسم العلمي' : 'Scientific Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.isArabic ? 'الوصف' : 'Description',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: careCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.careGuidelines,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final updated = await _speciesService.updateSpecies(
                  id: species.id,
                  commonName: commonNameCtrl.text,
                  scientificName: scientificCtrl.text,
                  description: descCtrl.text,
                  careInstructions: careCtrl.text,
                );
                if (mounted) {
                  setState(() {
                    final idx = _speciesList.indexWhere((s) => s.id == species.id);
                    if (idx != -1) {
                      _speciesList[idx] = updated;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      content: Text(l10n.isArabic ? 'تم تحديث النوع بنجاح' : 'Species updated successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.manageEncyclopediaTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.isArabic ? 'إضافة نبتة يدوياً' : 'Add Species'),
        onPressed: _showAddSpeciesDialog,
      ),
      body: Column(
        children: [
          // Search & Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchEncyclopedia,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _loadSpecies();
                        },
                      )
                    : null,
              ),
              onChanged: (val) => _loadSpecies(query: val),
            ),
          ),

          // List of Species
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_errorMessage!),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _loadSpecies(),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _speciesList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final sp = _speciesList[idx];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: sp.isPublished
                                    ? AppColors.primary.withAlpha(120)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: sp.isPublished
                                            ? AppColors.lightGreen
                                            : Colors.grey.shade200,
                                        child: Icon(
                                          Icons.spa_rounded,
                                          size: 20,
                                          color: sp.isPublished ? AppColors.primary : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sp.commonName,
                                              style: const TextStyle(
                                                fontFamily: AppTheme.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.dark,
                                              ),
                                            ),
                                            if (sp.scientificName != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                sp.scientificName!,
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                  color: AppColors.dark.withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                        tooltip: l10n.edit,
                                        onPressed: () => _showEditSpeciesDialog(sp),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                        tooltip: l10n.isArabic ? 'حذف من الموسوعة' : 'Delete',
                                        onPressed: () => _confirmDeleteSpecies(sp),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            sp.isPublished ? Icons.public : Icons.lock_outline,
                                            size: 16,
                                            color: sp.isPublished ? AppColors.primary : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            sp.isPublished ? l10n.publishedStatus : l10n.draftStatus,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: sp.isPublished ? AppColors.primary : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            l10n.isArabic ? 'حالة النشر:' : 'Publish:',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: sp.isPublished,
                                            activeColor: AppColors.primary,
                                            onChanged: (val) => _togglePublish(sp, val),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
