import 'package:flutter/material.dart';

import '../models/song.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;

  const SongListTile({
    super.key,
    required this.song,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(
        song.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: song.artist.isNotEmpty
          ? Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.key != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                song.key!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              song.isFavorite ? Icons.star : Icons.star_outline,
              color: song.isFavorite
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: song.isFavorite ? 'Remove from favourites' : 'Add to favourites',
            onPressed: onToggleFavorite,
          ),
          PopupMenuButton<_Action>(
            onSelected: (action) {
              if (action == _Action.delete) onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _Action.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Action { delete }
