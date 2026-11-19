import 'package:flutter/material.dart';

import 'note_editor_screen.dart';

/// Opens a note in view mode; [edit] opens it ready to type (new notes) and
/// [find] starts find-in-note with that text.
Future<void> openNote(
  BuildContext context,
  String path, {
  bool edit = false,
  String? find,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => NoteEditorScreen(path: path, edit: edit, find: find),
  ),
);
