import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';

class EditSongScreen extends StatefulWidget {
  final Song song;
  const EditSongScreen({super.key, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  late final TextEditingController _title;
  late final TextEditingController _artist;
  late final TextEditingController _key;
  late final TextEditingController _capo;
  late final TextEditingController _tempo;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.song.title);
    _artist = TextEditingController(text: widget.song.artist);
    _key = TextEditingController(text: widget.song.key ?? '');
    _capo = TextEditingController(
        text: widget.song.capo != null ? '${widget.song.capo}' : '');
    _tempo = TextEditingController(
        text: widget.song.tempo != null ? '${widget.song.tempo}' : '');
  }

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _key.dispose();
    _capo.dispose();
    _tempo.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.song.copyWith(
      title: _title.text.trim(),
      artist: _artist.text.trim(),
      key: _key.text.trim().isEmpty ? null : _key.text.trim(),
      capo: _capo.text.trim().isEmpty ? null : int.tryParse(_capo.text.trim()),
      tempo:
          _tempo.text.trim().isEmpty ? null : int.tryParse(_tempo.text.trim()),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit song details'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _artist,
              decoration: const InputDecoration(labelText: 'Artist'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _key,
              decoration: const InputDecoration(
                  labelText: 'Key', hintText: 'e.g. G, Am, Bb'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _capo,
              decoration:
                  const InputDecoration(labelText: 'Capo', hintText: '0–12'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 0 || n > 12) {
                  return 'Enter a number between 0 and 12';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tempo,
              decoration: const InputDecoration(
                labelText: 'Tempo (BPM)',
                hintText: 'e.g. 120 — used for tempo-synced auto-scroll',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final n = int.tryParse(v);
                if (n == null || n < 20 || n > 300) {
                  return 'Enter a number between 20 and 300';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
