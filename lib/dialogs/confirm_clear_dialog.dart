import 'package:flutter/material.dart';

Future<bool> showConfirmClearDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Tüm kayıtlar silinsin mi?'),
        content: const Text('Tüm uyku geçmişi kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      );
    },
  );

  return ok == true;
}
