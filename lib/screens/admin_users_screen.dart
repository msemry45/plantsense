import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_toggle_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  List<UserProfile> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase.from('profiles').select().order('created_at');
      setState(() {
        _users = response.map((e) => UserProfile.fromJson(e)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('${context.l10n.failedToLoadUsers}: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _supabase.from('profiles').update({'status': newStatus}).eq('id', id);
      _fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('${context.l10n.failedToUpdateStatus}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _updateRole(String id, String newRole) async {
    try {
      await _supabase.from('profiles').update({'role': newRole}).eq('id', id);
      _fetchUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('${context.l10n.failedToUpdateRole}: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text(l10n.manageUsersTitle),
        actions: [
          const LanguageToggleButton(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: _fetchUsers,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isSuspended = user.status == 'suspended';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSuspended
                                    ? AppColors.errorContainer
                                    : AppColors.lightGreen,
                                child: Icon(
                                  user.role == 'admin'
                                      ? Icons.admin_panel_settings_rounded
                                      : user.role == 'farmer'
                                          ? Icons.eco_rounded
                                          : Icons.visibility_outlined,
                                  color: isSuspended ? AppColors.error : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.fullName ?? user.username,
                                      style: const TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    Text(
                                      '@${user.username}',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 13,
                                        color: AppColors.dark.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Role Selector
                              Row(
                                children: [
                                  Text(
                                    l10n.rolePrefix,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark.withOpacity(0.7),
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: user.role,
                                    underline: const SizedBox.shrink(),
                                    style: const TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                    items: ['farmer', 'admin', 'viewer']
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e == 'farmer'
                                                    ? l10n.roleFarmer
                                                    : e == 'admin'
                                                        ? l10n.roleAdmin
                                                        : l10n.roleViewer,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null && val != user.role) {
                                        _updateRole(user.id, val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              // Status Selector
                              Row(
                                children: [
                                  Text(
                                    l10n.statusPrefix,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dark.withOpacity(0.7),
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: user.status,
                                    underline: const SizedBox.shrink(),
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSuspended ? AppColors.error : AppColors.success,
                                    ),
                                    items: ['active', 'suspended']
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e == 'active' ? l10n.activeStatus : l10n.suspendedStatus,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null && val != user.status) {
                                        _updateStatus(user.id, val);
                                      }
                                    },
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
    );
  }
}
