import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/vin_decoder.dart';

/// Офлайн-проверка VIN перед покупкой б/у авто: страна, вероятный бренд,
/// примерный год, валидность контрольной суммы. Не заменяет платную проверку
/// истории (ДТП/пробег/залоги) — об этом прямо предупреждаем пользователя.
class VinDecoderScreen extends StatefulWidget {
  const VinDecoderScreen({Key? key}) : super(key: key);

  @override
  State<VinDecoderScreen> createState() => _VinDecoderScreenState();
}

class _VinDecoderScreenState extends State<VinDecoderScreen> {
  final _controller = TextEditingController();
  VinDecodeResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _decode() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _result = decodeVin(text));
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Проверка VIN'), backgroundColor: AppColors.black),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 17,
            decoration: const InputDecoration(
              labelText: 'VIN-номер (17 символов)',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _decode(),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _decode,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
              child: const Text('Проверить', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
          if (r != null) ...[
            if (!r.formatValid)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(r.warnings.join('\n'), style: const TextStyle(color: AppColors.red)),
              )
            else ...[
              _infoRow('VIN', r.vin),
              _infoRow('Формат', 'корректный (17 символов)'),
              if (r.checksumValid != null)
                _infoRow('Контрольная сумма', r.checksumValid! ? 'сходится ✓' : 'не сходится ⚠️'),
              if (r.countryRegion != null) _infoRow('Регион производства', r.countryRegion!),
              if (r.manufacturerHint != null) _infoRow('Вероятный бренд', r.manufacturerHint!),
              if (r.approximateYear != null) _infoRow('Примерный год', '${r.approximateYear}'),
              if (r.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...r.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('⚠️ $w', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                  ),
                ),
              ],
            ],
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.steel),
            ),
            child: const Text(vinLimitationsNote, style: TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: Text(label, style: const TextStyle(color: AppColors.textMutedDark))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
