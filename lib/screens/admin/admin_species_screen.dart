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
                        padding: const EdgeInsets.all(16),
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
