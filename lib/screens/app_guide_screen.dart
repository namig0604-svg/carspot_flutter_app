import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';

class _GuideItem {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descriptionKey;
  const _GuideItem(this.icon, this.color, this.titleKey, this.descriptionKey);
}

class _GuideSection {
  final String titleKey;
  final List<_GuideItem> items;
  const _GuideSection(this.titleKey, this.items);
}

const List<_GuideSection> _guideSections = [
  _GuideSection('guide.section_main_nav', [
    _GuideItem(Icons.calendar_today, AppColors.blue, 'guide.nav_events_title', 'guide.nav_events_desc'),
    _GuideItem(Icons.map, AppColors.blue, 'guide.nav_map_title', 'guide.nav_map_desc'),
    _GuideItem(Icons.add_circle, AppColors.red, 'guide.nav_add_title', 'guide.nav_add_desc'),
    _GuideItem(Icons.chat_bubble, Colors.deepOrange, 'guide.nav_chats_title', 'guide.nav_chats_desc'),
    _GuideItem(Icons.person, Colors.cyan, 'guide.nav_profile_title', 'guide.nav_profile_desc'),
  ]),
  _GuideSection('faq.section_car', [
    _GuideItem(Icons.directions_car, Colors.cyan, 'guide.car_garage_title', 'guide.car_garage_desc'),
    _GuideItem(Icons.local_parking, Colors.indigo, 'guide.car_parking_title', 'guide.car_parking_desc'),
    _GuideItem(Icons.build, Colors.brown, 'guide.car_service_title', 'guide.car_service_desc'),
    _GuideItem(Icons.description, Colors.blueGrey, 'guide.car_documents_title', 'guide.car_documents_desc'),
    _GuideItem(Icons.attach_money, Colors.green, 'guide.car_expenses_title', 'guide.car_expenses_desc'),
    _GuideItem(Icons.local_gas_station, Colors.teal, 'guide.car_fuel_title', 'guide.car_fuel_desc'),
    _GuideItem(Icons.qr_code_scanner, Colors.purple, 'guide.car_vin_title', 'guide.car_vin_desc'),
  ]),
  _GuideSection('faq.section_community', [
    _GuideItem(Icons.people, AppColors.blue, 'guide.community_friends_title', 'guide.community_friends_desc'),
    _GuideItem(Icons.groups, AppColors.blue, 'guide.community_clubs_title', 'guide.community_clubs_desc'),
    _GuideItem(Icons.forum, Colors.deepOrange, 'guide.community_forum_title', 'guide.community_forum_desc'),
    _GuideItem(Icons.storefront, Colors.deepPurple, 'guide.community_marketplace_title', 'guide.community_marketplace_desc'),
    _GuideItem(Icons.sell_outlined, Colors.deepPurple, 'guide.community_car_listings_title', 'guide.community_car_listings_desc'),
    _GuideItem(Icons.how_to_vote, Colors.orangeAccent, 'guide.community_car_of_week_title', 'guide.community_car_of_week_desc'),
    _GuideItem(Icons.route, AppColors.blue, 'guide.community_convoy_title', 'guide.community_convoy_desc'),
    _GuideItem(Icons.emoji_events, Colors.amber, 'guide.community_leaderboard_title', 'guide.community_leaderboard_desc'),
  ]),
  _GuideSection('guide.section_activity', [
    _GuideItem(Icons.event_available, Colors.tealAccent, 'guide.activity_bookings_title', 'guide.activity_bookings_desc'),
    _GuideItem(Icons.bookmark, AppColors.red, 'guide.activity_favorites_title', 'guide.activity_favorites_desc'),
    _GuideItem(Icons.military_tech, Colors.amber, 'guide.activity_achievements_title', 'guide.activity_achievements_desc'),
    _GuideItem(Icons.flag, Colors.deepOrange, 'guide.activity_challenges_title', 'guide.activity_challenges_desc'),
  ]),
  _GuideSection('faq.section_safety', [
    _GuideItem(Icons.sos, Colors.red, 'guide.safety_sos_title', 'guide.safety_sos_desc'),
    _GuideItem(Icons.warning_amber_rounded, Colors.orange, 'guide.safety_hazards_title', 'guide.safety_hazards_desc'),
    _GuideItem(Icons.car_repair, AppColors.red, 'guide.safety_services_title', 'guide.safety_services_desc'),
    _GuideItem(Icons.pin_drop, Colors.teal, 'guide.safety_places_title', 'guide.safety_places_desc'),
  ]),
  _GuideSection('guide.section_other', [
    _GuideItem(Icons.settings, Colors.grey, 'guide.other_settings_title', 'guide.other_settings_desc'),
    _GuideItem(Icons.workspace_premium, Colors.amber, 'guide.other_premium_title', 'guide.other_premium_desc'),
  ]),
];

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('faq.guide_card_title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topLeft, imageAsset: 'assets/backgrounds/events.jpg'),
          ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.t('guide.intro_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 8),
                      Text(
                        context.t('guide.intro_body'),
                        style: TextStyle(fontSize: 14, color: AppColors.textMuted(context), height: 1.5),
                      ),
                    ],
                  ),
                ),
                for (final section in _guideSections) ...[
                  const SizedBox(height: 22),
                  Text(context.t(section.titleKey), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  for (final item in section.items)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: item.color.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Icon(item.icon, color: item.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.t(item.titleKey), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(context.t(item.descriptionKey), style: TextStyle(fontSize: 12.5, color: AppColors.textMuted(context), height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 10),
              ],
          ),
        ],
      ),
    );
  }
}
