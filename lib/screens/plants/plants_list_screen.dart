import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plant.dart';
import '../../services/plant_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_toggle_button.dart';

class PlantsListScreen extends StatefulWidget {
  final PlantService? plantService;
  final AuthService? authService;

  const PlantsListScreen({
    super.key,
    this.plantService,
    this.authService,
  });

  @override
  State<PlantsListScreen> createState() => _PlantsListScreenState();
}

class _PlantsListScreenState extends State<PlantsListScreen> {
  late final PlantService _plantService;
  late final AuthService _authService;

  List<Plant> _plants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plantService = widget.plantService ?? PlantService();
    _authService = widget.authService ?? AuthService();
    _loadPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plants = await _plantService.getPlants(search: _searchQuery);
      if (mounted) {
        setState(() {
          _plants = plants;
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

  bool get _canCreatePlant {
    final role = _authService.currentUserProfile?.role;
    return role == 'farmer' || role == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plantsListTitle),
        elevation: 0,
        actions: [
          const LanguageToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadPlants,
          ),
        ],
      ),
      floatingActionButton: _canCreatePlant
          ? FloatingActionButton.extended(
              onPressed: () async {
                final created = await context.push<bool>('/plants/new');
                if (created == true) {
                  _loadPlants();
                }
              },
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                l10n.addNewPlant,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.lightBackground,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchPlantsHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          _loadPlants();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value.trim());
                _loadPlants();
              },
            ),
          ),

          // Content Area
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

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
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: AppColors.semanticError),
              const SizedBox(height: 12),
              Text(
                l10n.isArabic ? 'فشل تحميل قائمة النباتات' : 'Failed to load plants',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPlants,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_plants.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen.withAlpha(128),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  size: 48,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchQuery.isNotEmpty
                    ? l10n.noPlantsFound
                    : l10n.noPlantsRecordedYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.dark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? (l10n.isArabic
                        ? 'جرب البحث باسم مختلف أو مسح حقل البحث.'
                        : 'Try searching with a different name or clear the filter.')
                    : l10n.addFirstPlantPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              if (_canCreatePlant && _searchQuery.isEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await context.push<bool>('/plants/new');
                    if (created == true) {
                      _loadPlants();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addNewPlant),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _loadPlants,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _plants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final plant = _plants[index];
          return _buildPlantCard(plant);
        },
      ),
    );
  }

  Widget _buildPlantCard(Plant plant) {
    final l10n = context.l10n;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.lightGreen.withAlpha(150), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.push('/plants/${plant.id}');
          _loadPlants();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 76,
                  height: 76,
                  color: AppColors.lightGreen.withAlpha(100),
                  child: plant.latestImageUrl != null
                      ? Image.network(
                          plant.latestImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.local_florist,
                            size: 36,
                            color: AppColors.primaryGreen,
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        )
                      : const Icon(
                          Icons.local_florist,
                          size: 36,
                          color: AppColors.primaryGreen,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plant.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.dark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (plant.status == 'archived')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.isArabic ? 'مؤرشف' : 'Archived',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Species Chip
                    if (plant.species != null)
                      Text(
                        plant.species!.commonName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    else
                      Text(
                        l10n.isArabic ? 'نبات عام' : 'General Plant',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    const SizedBox(height: 6),

                    // Metadata row: location & age
                    Row(
                      children: [
                        if (plant.location != null && plant.location!.isNotEmpty) ...[
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              plant.location!,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (plant.daysSincePlanted != null) ...[
                          const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black45),
                          const SizedBox(width: 3),
                          Text(
                            l10n.daysOld(plant.daysSincePlanted!),
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                l10n.isArabic ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
