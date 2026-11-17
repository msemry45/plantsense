import 'package:flutter/material.dart';
import '../../models/species.dart';
import '../../services/species_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class EncyclopediaScreen extends StatefulWidget {
  final SpeciesService? speciesService;
  final bool isGuest;

  const EncyclopediaScreen({
    super.key,
    this.speciesService,
    this.isGuest = false,
  });

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  late final SpeciesService _speciesService;
  final TextEditingController _searchController = TextEditingController();

  List<Species> _speciesList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _speciesService = widget.speciesService ?? SpeciesService();
    _loadPublishedSpecies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPublishedSpecies({String? query}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _speciesService.getPublishedSpecies(search: query);
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

  void _showSpeciesDetails(Species species) {
    final l10n = context.l10n;
    final isArabic = l10n.isArabic;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.eco_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          species.localizedName(isArabic),
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                          ),
                        ),
                        if (species.scientificName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            species.scientificName!,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.dark.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (species.localizedDescription(isArabic) != null &&
                  species.localizedDescription(isArabic)!.isNotEmpty) ...[
                Text(
                  species.localizedDescription(isArabic)!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.dark.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                l10n.idealConditions,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightGreen.withAlpha(120)),
                ),
                child: Column(
                  children: [
                    _buildConditionRow(
                      Icons.light_mode_outlined,
                      l10n.lightConditions,
                      species.idealLightConditions ?? (isArabic ? 'ضوء ساطع غير مباشر' : 'Bright indirect light'),
                    ),
                    const Divider(height: 20),
                    _buildConditionRow(
                      Icons.thermostat_outlined,
                      l10n.temperatureRange,
                      '${species.idealTemperatureMin ?? 18}°C - ${species.idealTemperatureMax ?? 28}°C',
                    ),
                    const Divider(height: 20),
                    _buildConditionRow(
                      Icons.water_drop_outlined,
                      l10n.humidityRange,
                      '${species.idealHumidityMin ?? 50}% - ${species.idealHumidityMax ?? 75}%',
                    ),
                  ],
                ),
              ),
              if (species.localizedCareInstructions(isArabic) != null &&
                  species.localizedCareInstructions(isArabic)!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.careGuidelines,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    species.localizedCareInstructions(isArabic)!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.dark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.dark,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.dark.withOpacity(0.75),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.encyclopediaTitle),
        actions: const [
          LanguageToggleButton(),
        ],
      ),
      body: Column(
        children: [
          // Search Header
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
                          _loadPublishedSpecies();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                _loadPublishedSpecies(query: val);
              },
            ),
          ),

          // Species List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadPublishedSpecies(),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _speciesList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.isArabic
                                      ? 'لا توجد نباتات منشورة مطابقة للبحث'
                                      : 'No published plants match search',
                                  style: const TextStyle(color: Colors.grey),
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
                                    color: AppColors.lightGreen.withAlpha(120),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: const CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.lightGreen,
                                    child: Icon(Icons.spa_rounded, color: AppColors.primary, size: 28),
                                  ),
                                  title: Text(
                                    sp.localizedName(l10n.isArabic),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.thermostat_outlined, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${sp.idealTemperatureMin ?? 18}° - ${sp.idealTemperatureMax ?? 28}°C',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const SizedBox(width: 14),
                                          const Icon(Icons.water_drop_outlined, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${sp.idealHumidityMin ?? 50}% - ${sp.idealHumidityMax ?? 75}%',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                  onTap: () => _showSpeciesDetails(sp),
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
