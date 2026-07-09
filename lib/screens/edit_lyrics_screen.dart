import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/chordpro_parser.dart';

class EditLyricsScreen extends StatefulWidget {
  final Song song;
  const EditLyricsScreen({super.key, required this.song});

  @override
  State<EditLyricsScreen> createState() => _EditLyricsScreenState();
}

class _EditLyricsScreenState extends State<EditLyricsScreen> {
  late final TextEditingController _content;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.song.content);
    _content.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  void _save() {
    final content = _content.text;
    final meta = ChordProParser.extractMeta(content);
    final updated = widget.song.copyWith(
      content: content,
      title: meta.title.isNotEmpty ? meta.title : widget.song.title,
      artist: meta.artist.isNotEmpty ? meta.artist : widget.song.artist,
      key: meta.key ?? widget.song.key,
      capo: meta.capo ?? widget.song.capo,
      tempo: meta.tempo ?? widget.song.tempo,
    );
    Navigator.pop(context, updated);
  }

  /// Writes the current text out via Android's document picker (SAF), which
  /// lists Google Drive, Downloads, on-device storage, etc. as destinations.
  Future<void> _saveAs() async {
    final bytes = Uint8List.fromList(utf8.encode(_content.text));
    final baseName = widget.song.title.trim().isEmpty
        ? 'song'
        : widget.song.title.trim().replaceAll(RegExp(r'[^\w\- ]'), '_');
    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save lyrics file',
        fileName: '$baseName.cho',
        type: FileType.custom,
        allowedExtensions: ['cho'],
        bytes: bytes,
      );
      if (!mounted || savedPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save file: $e')),
        );
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved to the song.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit lyrics'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: 'Save a copy…',
              onPressed: _saveAs,
            ),
            TextButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _content,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '{title: Song Name}\n{artist: Artist}\n\n'
                  '[C]Lyrics with [G]chords…',
            ),
          ),
        ),
      ),
    );
  }
}
