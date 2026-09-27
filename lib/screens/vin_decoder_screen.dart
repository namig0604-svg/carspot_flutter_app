import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/vin_decoder.dart';
import '../l10n/l10n_extensions.dart';

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
      appBar: AppBar(title: Text(context.t('vin.title')), backgroundColor: AppColors.black),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 17,
            decoration: InputDecoration(
              labelText: context.t('vin.input_label'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _decode(),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _decode,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
              child: Text(context.t('vin.check_button'), style: const TextStyle(color: Colors.white)),
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
                child: Text(r.warnings.map((k) => context.t(k)).join('\n'), style: const TextStyle(color: AppColors.red)),
              )
            else ...[
              _infoRow('VIN', r.vin),
              _infoRow(context.t('vin.label_format'), context.t('vin.format_valid_value')),
              if (r.checksumValid != null)
                _infoRow(context.t('vin.label_checksum'), r.checksumValid! ? context.t('vin.checksum_ok') : context.t('vin.checksum_fail')),
              if (r.countryRegion != null) _infoRow(context.t('vin.label_country'), context.t(r.countryRegion!)),
              if (r.manufacturerHint != null) _infoRow(context.t('vin.label_brand'), r.manufacturerHint!),
              if (r.approximateYear != null) _infoRow(context.t('vin.label_year'), '${r.approximateYear}'),
              if (r.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...r.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('⚠️ ${context.t(w)}', style: const TextStyle(fontSize: 12, color: Colors.amber)),
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
            child: Text(context.t(vinLimitationsNoteKey), style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark)),
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
