import 'package:flutter/material.dart';
import '../../models/observation_note.dart';
import '../../services/observation_note_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_toggle_button.dart';

class PlantNotesScreen extends StatefulWidget {
  final String plantId;
  final String plantName;
  final ObservationNoteService? noteService;
  final AuthService? authService;

  const PlantNotesScreen({
    super.key,
    required this.plantId,
    required this.plantName,
    this.noteService,
    this.authService,
  });

  @override
  State<PlantNotesScreen> createState() => _PlantNotesScreenState();
}

class _PlantNotesScreenState extends State<PlantNotesScreen> {
  late final ObservationNoteService _noteService;
  late final AuthService _authService;

  List<ObservationNote> _notes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _noteService = widget.noteService ?? ObservationNoteService();
    _authService = widget.authService ?? AuthService();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notes = await _noteService.getNotes(widget.plantId);
      if (mounted) {
        setState(() {
          _notes = notes;
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

  Future<void> _showNoteDialog({ObservationNote? existingNote}) async {
    final l10n = context.l10n;
    final isEdit = existingNote != null;
    final controller = TextEditingController(text: existingNote?.note ?? '');
    DateTime observedDate = existingNote?.observedAt ?? DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEdit ? l10n.editObservationNoteDialogTitle : l10n.addObservationNoteDialogTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l10n.noteHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: observedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => observedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.noteDatePrefix} ${observedDate.year}-${observedDate.month.toString().padLeft(2, '0')}-${observedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 13, color: AppColors.dark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text(isEdit ? l10n.save : l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      try {
        if (isEdit) {
          await _noteService.updateNote(
            noteId: existingNote.id,
            note: controller.text.trim(),
          );
        } else {
          await _noteService.addNote(
            plantId: widget.plantId,
            note: controller.text.trim(),
            observedAt: observedDate,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? l10n.noteUpdatedSuccess : l10n.noteSavedSuccess),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
        _loadNotes();
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

  Future<void> _deleteNote(ObservationNote note) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNoteTitle),
        content: Text(l10n.deleteNoteConfirm),
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

    if (confirmed == true) {
      try {
        await _noteService.deleteNote(note.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noteDeletedSuccess),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
        _loadNotes();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notesTitle(widget.plantName)),
        elevation: 0,
        actions: [
          const LanguageToggleButton(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _loadNotes,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _canMutate
          ? FloatingActionButton.extended(
              onPressed: () => _showNoteDialog(),
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.note_add),
              label: Text(l10n.recordFirstNote, style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
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
                onPressed: _loadNotes,
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = context.l10n;

    if (_notes.isEmpty) {
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
                  Icons.rate_review_outlined,
                  size: 44,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noObservationNotesYet,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.notesDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              if (_canMutate) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showNoteDialog(),
                  icon: const Icon(Icons.note_add),
                  label: Text(l10n.recordFirstNote),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _loadNotes,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = _notes[index];
          final dateStr =
              '${note.observedAt.year}-${note.observedAt.month.toString().padLeft(2, '0')}-${note.observedAt.day.toString().padLeft(2, '0')}';

          return Card(
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.lightGreen.withAlpha(130)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      if (_canMutate)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_vert, size: 18, color: Colors.black45),
                          onSelected: (action) {
                            if (action == 'edit') {
                              _showNoteDialog(existingNote: note);
                            } else if (action == 'delete') {
                              _deleteNote(note);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(l10n.edit),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.delete, style: const TextStyle(color: AppColors.semanticError)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note.note,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.dark,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

