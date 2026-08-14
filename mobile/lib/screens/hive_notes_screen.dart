import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/models.dart';
import '../services/group_shared_data_sync.dart';
import '../theme/app_theme.dart';
import '../widgets/hive_editors.dart';
import '../widgets/home_fab.dart';
import '../utils/system_insets.dart';

class HiveNotesScreen extends StatefulWidget {
  const HiveNotesScreen({super.key, required this.hiveUuid, this.hiveLabel});

  final String hiveUuid;
  final String? hiveLabel;

  @override
  State<HiveNotesScreen> createState() => _HiveNotesScreenState();
}

class _HiveNotesScreenState extends State<HiveNotesScreen> {
  final db = AppDatabase.instance;
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final notes = await db.notesForHive(widget.hiveUuid);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _addOrEdit({Note? existing}) async {
    final saved = await editNoteDialog(context, hiveUuid: widget.hiveUuid, existing: existing);
    if (saved) await _reload();
  }

  Future<void> _delete(Note n) async {
    if (!await confirmDialog(context, 'Obriši napomenu', 'Obrisati ovu napomenu?')) return;
    await db.softDelete('note', n.uuid);
    await GroupSharedDataSync().onNoteDeleted(n);
    await _reload();
  }

  Future<void> _openDetails(Note n) async {
    await showNoteDetailsDialog(
      context,
      note: n,
      onEdit: () => _addOrEdit(existing: n),
      onDelete: () => _delete(n),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hiveLabel == null ? 'Napomene' : 'Napomene · ${widget.hiveLabel}'),
      ),
      floatingActionButton: HomeFab.pair(
        primary: FloatingActionButton.extended(
          heroTag: 'add_note_fab',
          onPressed: () => _addOrEdit(),
          icon: const Icon(Icons.add),
          label: const Text('Dodaj'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('Nema napomena.'))
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, fabClearancePadding(context)),
                  itemCount: _notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = _notes[i];
                    return Material(
                      color: AppTheme.card(context),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: Icon(
                          n.reminderAt != null ? Icons.alarm : Icons.notes,
                          color: AppColors.meadow,
                        ),
                        title: Text(
                          notePreviewLine(n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text([
                          n.dateCreated.toLocal().toString().split('.').first,
                          if (n.reminderAt != null)
                            'Podsetnik: ${n.reminderAt!.toLocal().toString().split('.').first}',
                        ].join(' · ')),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') await _addOrEdit(existing: n);
                            if (v == 'delete') await _delete(n);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Izmeni')),
                            PopupMenuItem(value: 'delete', child: Text('Obriši')),
                          ],
                        ),
                        onTap: () => _openDetails(n),
                      ),
                    );
                  },
                ),
    );
  }
}
