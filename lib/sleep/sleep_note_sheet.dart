import 'package:flutter/material.dart';

/// Uyku notu ekleme / düzenleme bottom sheet
/// - max 200 karakter
/// - Kaydet / Vazgeç her zaman erişilebilir
/// - Controller lifecycle güvenli
/// - Hem ilk kayıt hem edit için kullanılabilir
Future<String?> showSleepNoteSheet({
  required BuildContext context,
  required String title,
  String initialText = '',
}) async {
  final textController = TextEditingController(text: initialText);

  final result = await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    isDismissible: false, // dışarı dokununca kapanmasın
    enableDrag: false, // aşağı çekip kapatma kapalı
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TITLE
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 12),

              // TEXT FIELD
              TextField(
                controller: textController,
                autofocus: true,
                maxLength: 200,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Örn: Gazlıydı, zor uyudu...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // ACTIONS
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext, null);
                    },
                    child: const Text('Vazgeç'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final text = textController.text.trim();
                      Navigator.pop(sheetContext, text.isEmpty ? null : text);
                    },
                    child: const Text('Kaydet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  // ⚠️ controller'ı MUTLAKA burada dispose ediyoruz
  textController.dispose();

  return result;
}
