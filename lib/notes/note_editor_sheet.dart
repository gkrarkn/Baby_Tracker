// lib/notes/note_editor_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_globals.dart';
import 'note_model.dart';

class NoteEditorSheet extends StatefulWidget {
  final Note? note;
  final ValueChanged<Note> onSave;

  const NoteEditorSheet({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  static const int _maxChars = 1200;

  late final TextEditingController _textCtrl;
  late final FocusNode _focus;

  bool _dirty = false;

  bool get _isEdit => widget.note != null;

  String get _initialText => widget.note?.text ?? '';

  String get _cleanText => _textCtrl.text.trim();

  bool get _canSave =>
      _cleanText.isNotEmpty && _cleanText != _initialText.trim();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: _initialText);
    _focus = FocusNode();

    _textCtrl.addListener(() {
      final nowDirty = _textCtrl.text != _initialText;
      if (nowDirty != _dirty) setState(() => _dirty = nowDirty);
      // Save button enable/disable için:
      setState(() {});
    });

    // BottomSheet açılınca klavye otomatik gelsin
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<bool> _confirmCloseIfDirty() async {
    if (!_dirty) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Değişiklikler kaybolacak'),
          content: const Text('Kaydetmeden çıkmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Vazgeç',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Çık'),
            ),
          ],
        );
      },
    );

    return ok == true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _copyAll() async {
    final txt = _textCtrl.text;
    if (txt.trim().isEmpty) {
      _showSnack('Kopyalanacak içerik yok.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: txt));
    _showSnack('Kopyalandı.');
    HapticFeedback.lightImpact();
  }

  void _insertTimestamp() {
    final stamp = getCurrentDateTime();
    final insert = '[$stamp]\n';

    final value = _textCtrl.value;
    final sel = value.selection;
    final text = value.text;

    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;

    final newText = text.replaceRange(start, end, insert);
    final newCursor = start + insert.length;

    _textCtrl.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );

    HapticFeedback.selectionClick();
  }

  void _save() {
    final cleaned = _cleanText;

    // ✅ Boş not engeli (hard guard)
    if (cleaned.isEmpty) {
      _showSnack('Boş not kaydedilemez.');
      HapticFeedback.mediumImpact();
      return;
    }

    final now = DateTime.now();

    // Not modelin “text-only” olduğu için burada text’i tek alan gibi yönetiyoruz.
    final saved = (widget.note == null)
        ? Note(
            id: now.microsecondsSinceEpoch.toString(),
            text: cleaned,
            createdAt: now,
            pinned: false,
            reminderAt: null,
            notificationId: null,
          )
        : widget.note!.copyWith(text: cleaned);

    widget.onSave(saved);
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mainColor = appThemeColor.value;

    return WillPopScope(
      onWillPop: () async => _confirmCloseIfDirty(),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            top: 10,
            bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Material(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEdit ? 'Notu Düzenle' : 'Yeni Not',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kopyala',
                        onPressed: _copyAll,
                        icon: Icon(
                          Icons.copy_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        onPressed: () async {
                          final ok = await _confirmCloseIfDirty();
                          if (ok && mounted) Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Quick actions
                  Row(
                    children: [
                      _chipButton(
                        context,
                        label: 'Zaman damgası ekle',
                        icon: Icons.schedule_rounded,
                        color: mainColor,
                        onTap: _insertTimestamp,
                      ),
                      const SizedBox(width: 10),
                      _chipButton(
                        context,
                        label: 'Temizle',
                        icon: Icons.cleaning_services_rounded,
                        color: cs.onSurfaceVariant,
                        onTap: () {
                          if (_textCtrl.text.isEmpty) return;
                          _textCtrl.clear();
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Editor
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: TextField(
                        controller: _textCtrl,
                        focusNode: _focus,
                        maxLines: 10,
                        minLines: 6,
                        maxLength: _maxChars,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          fontSize: 14.5,
                          height: 1.25,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Notunuzu yazın…',
                          hintStyle: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          border: InputBorder.none,
                          counterStyle: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: (_cleanText.isEmpty) ? null : _save,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _isEdit ? 'Kaydet' : 'Notu Oluştur',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: cs.onSurface.withValues(
                          alpha: 0.10,
                        ),
                        disabledForegroundColor: cs.onSurfaceVariant.withValues(
                          alpha: 0.55,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Micro helper line
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _cleanText.isEmpty
                          ? 'Boş not kaydedilemez.'
                          : (_canSave
                                ? 'Kaydetmeye hazır.'
                                : 'Değişiklik yok.'),
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w800,
                        color: cs.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
