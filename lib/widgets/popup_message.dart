import 'package:flutter/material.dart';

/// 全屏偏大嘅結果彈窗——重要資訊唔再藏喺細字 log。
Future<void> showOutcomePopup(
  BuildContext context, {
  required String message,
  String title = '結果',
  String confirmLabel = '知道',
  int remaining = 0,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: const Color(0xFF12161C),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3D4A5C), width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8A838),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFFF0F3F6),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (remaining > 0)
                      Text(
                        '仲有 $remaining 則',
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFD8DEE6),
                        fontSize: 15,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2F6FED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      remaining > 0 ? '下一則' : confirmLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String popupTitleFor(String message) {
  final m = message;
  if (m.contains('DSE') || m.contains('放榜')) return '考試／放榜';
  if (m.contains('選科') || m.contains('選修')) return '選科';
  if (m.contains('Foundation') ||
      m.contains('JUPAS') ||
      m.contains('Asso') ||
      m.contains('升學')) {
    return '升學';
  }
  if (m.contains('入讀') || m.contains('大學') || m.contains('學校')) {
    return '學業';
  }
  if (m.contains('入職') || m.contains('辭') || m.contains('工')) return '事業';
  if (m.contains('稅') || m.contains('利是') || m.contains('\$')) return '金錢';
  return '結果';
}
