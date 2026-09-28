import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/car_loaders.dart';
import '../widgets/car_picker_field.dart';
import '../l10n/l10n_extensions.dart';

const Map<String, String> _maintenanceTypeRu = {
  'oil': 'Замена масла',
  'tires': 'Шины',
  'filters': 'Фильтры',
  'inspection': 'ТО / осмотр',
  'repair': 'Ремонт',
  'other': 'Другое',
};

const Map<String, String> _expenseCategoryRu = {
  'fuel': 'Топливо',
  'service': 'Сервис',
  'insurance': 'Страховка',
  'parking': 'Парковка',
  'carwash': 'Автомойка',
  'fines': 'Штрафы',
  'other': 'Другое',
};

const Map<String, String> _documentTypeRu = {
  'registration': 'Свидетельство о регистрации',
  'insurance_osago': 'ОСАГО',
  'insurance_kasko': 'КАСКО',
  'inspection': 'Техосмотр',
  'license': 'Права',
  'other': 'Другое',
};

String _fmtDate(dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString();
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

/// PDF-отчёт по машине — CarSpot Premium. Собирает сервисный журнал, расходы,
/// документы и топливную статистику машины из уже существующих эндпоинтов
/// в один PDF-файл, который можно скачать/переслать (например, при продаже
/// авто — подтверждённая история повышает доверие покупателя).
class CarReportScreen extends StatefulWidget {
  const CarReportScreen({Key? key}) : super(key: key);

  @override
  State<CarReportScreen> createState() => _CarReportScreenState();
}

class _CarReportScreenState extends State<CarReportScreen> {
  Map<String, dynamic>? _selectedCar;
  bool _isLoading = false;
  bool _isGenerating = false;

  List<dynamic> _maintenance = [];
  List<dynamic> _expenses = [];
  double _totalExpenses = 0;
  List<dynamic> _documents = [];
  List<dynamic> _fuelEntries = [];
  Map<String, dynamic> _fuelStats = {};

  Future<void> _onCarSelected(Map<String, dynamic> car) async {
    setState(() => _selectedCar = car);
    await _loadAll();
  }

  Future<void> _loadAll() async {
    final car = _selectedCar;
    if (car == null) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;
      final carId = car['id'];

      final results = await Future.wait([
        ApiService.get('/api/maintenance/car/$carId', token: token),
        ApiService.get('/api/car-expenses/car/$carId', token: token),
        ApiService.get('/api/car-documents/car/$carId', token: token),
        ApiService.get('/api/fuel-entries/car/$carId', token: token),
      ]);

      final maintenanceResp = results[0];
      final expensesResp = results[1];
      final documentsResp = results[2];
      final fuelResp = results[3];

      setState(() {
        _maintenance = maintenanceResp is Map && maintenanceResp['items'] is List ? maintenanceResp['items'] as List : [];
        _expenses = expensesResp is Map && expensesResp['items'] is List ? expensesResp['items'] as List : [];
        _totalExpenses = expensesResp is Map ? (expensesResp['total_amount'] as num?)?.toDouble() ?? 0 : 0;
        _documents = documentsResp is Map && documentsResp['items'] is List ? documentsResp['items'] as List : [];
        _fuelEntries = fuelResp is Map && fuelResp['items'] is List ? fuelResp['items'] as List : [];
        _fuelStats = fuelResp is Map && fuelResp['stats'] is Map ? Map<String, dynamic>.from(fuelResp['stats']) : {};
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAndSharePdf() async {
    final car = _selectedCar;
    if (car == null || _isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final regularFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final doc = pw.Document(theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont));

      final title = '${car['make'] ?? ''} ${car['model'] ?? ''}'.trim();
      final now = DateTime.now();
      final generatedAt = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('CarSpot — Отчёт об автомобиле', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text(title.isEmpty ? 'Без названия' : title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              [
                if (car['year'] != null) 'Год: ${car['year']}',
                if ((car['color'] ?? '').toString().isNotEmpty) 'Цвет: ${car['color']}',
                if ((car['license_plate'] ?? '').toString().isNotEmpty) 'Госномер: ${car['license_plate']}',
              ].join('   '),
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 2),
            pw.Text('Сформировано: $generatedAt', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 18),

            pw.Text('Сервисный журнал', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _maintenance.isEmpty
                ? pw.Text('Записей нет', style: const pw.TextStyle(color: PdfColors.grey600))
                : pw.TableHelper.fromTextArray(
                    headers: ['Дата', 'Тип', 'Описание', 'Пробег, км', 'Стоимость'],
                    data: _maintenance.map((m) {
                      final type = _maintenanceTypeRu[m['type']] ?? (m['type']?.toString() ?? '');
                      final cost = m['cost'] != null ? '${(m['cost'] as num).toStringAsFixed(0)} ₽' : '—';
                      final mileage = m['mileage_km'] != null ? '${m['mileage_km']}' : '—';
                      return [_fmtDate(m['done_at']), type, m['title']?.toString() ?? '', mileage, cost];
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
            pw.SizedBox(height: 18),

            pw.Text('Расходы на авто', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _expenses.isEmpty
                ? pw.Text('Записей нет', style: const pw.TextStyle(color: PdfColors.grey600))
                : pw.Column(children: [
                    pw.TableHelper.fromTextArray(
                      headers: ['Дата', 'Категория', 'Сумма', 'Заметка'],
                      data: _expenses.map((e) {
                        final cat = _expenseCategoryRu[e['category']] ?? (e['category']?.toString() ?? '');
                        final amount = '${(e['amount'] as num).toStringAsFixed(0)} ₽';
                        return [_fmtDate(e['date']), cat, amount, e['note']?.toString() ?? ''];
                      }).toList(),
                      cellStyle: const pw.TextStyle(fontSize: 9),
                      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      cellAlignment: pw.Alignment.centerLeft,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text('Итого: ${_totalExpenses.toStringAsFixed(0)} ₽', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ]),
            pw.SizedBox(height: 18),

            pw.Text('Документы', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _documents.isEmpty
                ? pw.Text('Документов нет', style: const pw.TextStyle(color: PdfColors.grey600))
                : pw.TableHelper.fromTextArray(
                    headers: ['Тип', 'Название', 'Действителен до'],
                    data: _documents.map((d) {
                      final type = _documentTypeRu[d['type']] ?? (d['type']?.toString() ?? '');
                      return [type, d['title']?.toString() ?? '', _fmtDate(d['expires_at'])];
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
            pw.SizedBox(height: 18),

            pw.Text('Топливо', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (_fuelStats.isNotEmpty)
              pw.Text(
                'Заправок: ${_fuelStats['total_entries'] ?? 0}   '
                'Всего литров: ${((_fuelStats['total_liters'] as num?) ?? 0).toStringAsFixed(1)}   '
                'Всего потрачено: ${((_fuelStats['total_cost'] as num?) ?? 0).toStringAsFixed(0)} ₽'
                '${_fuelStats['avg_consumption_l_100km'] != null ? '   Средний расход: ${(_fuelStats['avg_consumption_l_100km'] as num).toStringAsFixed(1)} л/100км' : ''}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            pw.SizedBox(height: 6),
            _fuelEntries.isEmpty
                ? pw.Text('Записей нет', style: const pw.TextStyle(color: PdfColors.grey600))
                : pw.TableHelper.fromTextArray(
                    headers: ['Дата', 'Литры', 'Сумма', 'Заправка'],
                    data: _fuelEntries.map((f) {
                      final liters = (f['liters'] as num).toStringAsFixed(1);
                      final cost = '${(f['total_cost'] as num).toStringAsFixed(0)} ₽';
                      return [_fmtDate(f['date']), liters, cost, f['station']?.toString() ?? ''];
                    }).toList(),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                  ),
            pw.SizedBox(height: 24),
            pw.Text('Сформировано в приложении CarSpot', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      );

      final bytes = await doc.save();
      final fileName = 'carspot_otchet_${(title.isEmpty ? 'auto' : title).replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('car_report.title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.t('car_report.hint'),
              style: TextStyle(fontSize: 12.5, color: cardText.withOpacity(0.6)),
            ),
            const SizedBox(height: 12),
            CarPickerField(onSelected: _onCarSelected),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: AppFullLoader()))
            else if (_selectedCar == null)
              const SizedBox.shrink()
            else ...[
              _summaryRow(context, Icons.build, context.tArgs('car_report.count_maintenance', {'n': '${_maintenance.length}'})),
              _summaryRow(context, Icons.attach_money, context.tArgs('car_report.count_expenses', {'n': '${_expenses.length}', 'sum': _totalExpenses.toStringAsFixed(0)})),
              _summaryRow(context, Icons.description, context.tArgs('car_report.count_documents', {'n': '${_documents.length}'})),
              _summaryRow(context, Icons.local_gas_station, context.tArgs('car_report.count_fuel', {'n': '${_fuelEntries.length}'})),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _isGenerating
                    ? const SizedBox(width: 18, height: 18, child: AppLoader(size: 18, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(context.t('car_report.generate_button')),
                onPressed: _isGenerating ? null : _generateAndSharePdf,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: cardText))),
        ],
      ),
    );
  }
}
