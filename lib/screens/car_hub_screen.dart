import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_menu_tile.dart';
import '../widgets/section_background.dart';
import 'garage_screen.dart';
import 'parking_screen.dart';
import 'maintenance_screen.dart';
import 'car_documents_screen.dart';
import 'car_expenses_screen.dart';
import 'fuel_tracker_screen.dart';
import 'trips_list_screen.dart';
import 'vin_decoder_screen.dart';
import 'ai_diagnosis_screen.dart';
import 'car_report_screen.dart';
import 'maintenance_forecast_screen.dart';
import 'premium_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Раздел "Машина" — всё, что касается конкретного авто, в одном месте:
/// гараж, парковка, сервисный дневник, документы, расходы, топливо,
/// VIN-проверка и Max-эксклюзивы (ИИ-диагностика/PDF-отчёт/прогноз ТО).
/// Вынесено из общего плоского меню (home_screen.dart) в отдельный экран,
/// чтобы на главном экране была всего одна крупная карточка "Машина", а не
/// десяток мелких иконок вперемешку с другими разделами.
class CarHubScreen extends StatelessWidget {
  final List<dynamic> myCars;
  final bool isMaxTier;
  final VoidCallback onCarsChanged;

  const CarHubScreen({
    Key? key,
    required this.myCars,
    required this.isMaxTier,
    required this.onCarsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('home.section_my_car'), overflow: TextOverflow.ellipsis, maxLines: 1),
        backgroundColor: AppColors.black,
        elevation: 0,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: Colors.cyan, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/garage.jpg'),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.directions_car,
                      label: context.t('home.menu_garage'),
                      color: Colors.cyan,
                      badge: myCars.isNotEmpty ? '${myCars.length}' : null,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GarageScreen()),
                      ).then((_) => onCarsChanged()),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.local_parking,
                      label: context.t('home.menu_parking'),
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ParkingScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.build,
                      label: context.t('home.menu_service_log'),
                      color: Colors.brown,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.description,
                      label: context.t('home.menu_documents'),
                      color: Colors.blueGrey,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarDocumentsScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.attach_money,
                      label: context.t('home.menu_expenses'),
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarExpensesScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.local_gas_station,
                      label: context.t('home.menu_fuel_tracker'),
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FuelTrackerScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.route,
                      label: context.t('home.menu_trips'),
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TripsListScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.qr_code_scanner,
                      label: context.t('home.menu_vin_check'),
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VinDecoderScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.psychology_alt,
                      label: context.t('home.menu_ai_diagnosis'),
                      color: Colors.deepOrange,
                      locked: !isMaxTier,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isMaxTier
                              ? AiDiagnosisScreen(carId: myCars.isNotEmpty ? myCars.first['id'] as String? : null)
                              : const PremiumScreen(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.picture_as_pdf,
                      label: context.t('home.menu_car_report'),
                      color: Colors.redAccent,
                      locked: !isMaxTier,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => isMaxTier ? const CarReportScreen() : const PremiumScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    child: AnimatedMenuTile(
                      icon: Icons.event_available,
                      label: context.t('home.menu_maintenance_forecast'),
                      color: Colors.teal,
                      locked: !isMaxTier,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => isMaxTier ? const MaintenanceForecastScreen() : const PremiumScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
