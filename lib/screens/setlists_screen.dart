import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/setlist.dart';
import '../providers/setlist_provider.dart';
import 'setlist_detail_screen.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final setlists = context.watch<SetlistProvider>().setlists;

    return Scaffold(
      appBar: AppBar(title: const Text('Setlists')),
      body: setlists.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No setlists yet.\nTap + to create one.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          : ListView.separated(
              itemCount: setlists.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final setlist = setlists[i];
                return ListTile(
                  title: Text(setlist.name),
                  leading: const Icon(Icons.queue_music),
                  trailing: PopupMenuButton<_Action>(
                    onSelected: (action) {
                      if (action == _Action.rename) {
                        _renameDialog(context, setlist);
                      } else {
                        _confirmDelete(context, setlist);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _Action.rename,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Rename'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SetlistDetailScreen(setlist: setlist),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDialog(context),
        tooltip: 'New setlist',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createDialog(BuildContext context) async {
    final name = await _nameDialog(context, title: 'New setlist');
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<SetlistProvider>().createSetlist(name);
    }
  }

  Future<void> _renameDialog(BuildContext context, Setlist setlist) async {
    final name = await _nameDialog(context,
        title: 'Rename setlist', initial: setlist.name);
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<SetlistProvider>().renameSetlist(setlist.id!, name);
    }
  }

  Future<String?> _nameDialog(BuildContext context,
      {required String title, String initial = ''}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Setlist name'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Setlist setlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete setlist'),
        content: Text(
            'Delete "${setlist.name}"? Songs will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<SetlistProvider>().deleteSetlist(setlist.id!);
    }
  }
}

enum _Action { rename, delete }
