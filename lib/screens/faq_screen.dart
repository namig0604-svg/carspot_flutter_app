import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';
import 'app_guide_screen.dart';

class _FaqItem {
  final String questionKey;
  final String answerKey;
  const _FaqItem(this.questionKey, this.answerKey);
}

class _FaqSection {
  final String titleKey;
  final IconData icon;
  final List<_FaqItem> items;
  const _FaqSection(this.titleKey, this.icon, this.items);
}

const List<_FaqSection> _faqSections = [
  _FaqSection('faq.section_account', Icons.person_outline, [
    _FaqItem('faq.account_q1', 'faq.account_a1'),
    _FaqItem('faq.account_q2', 'faq.account_a2'),
    _FaqItem('faq.account_q3', 'faq.account_a3'),
    _FaqItem('faq.account_q4', 'faq.account_a4'),
  ]),
  _FaqSection('faq.section_events', Icons.calendar_today_outlined, [
    _FaqItem('faq.events_q1', 'faq.events_a1'),
    _FaqItem('faq.events_q2', 'faq.events_a2'),
    _FaqItem('faq.events_q3', 'faq.events_a3'),
    _FaqItem('faq.events_q4', 'faq.events_a4'),
    _FaqItem('faq.events_q5', 'faq.events_a5'),
  ]),
  _FaqSection('faq.section_car', Icons.directions_car_outlined, [
    _FaqItem('faq.car_q1', 'faq.car_a1'),
    _FaqItem('faq.car_q2', 'faq.car_a2'),
    _FaqItem('faq.car_q3', 'faq.car_a3'),
    _FaqItem('faq.car_q4', 'faq.car_a4'),
    _FaqItem('faq.car_q5', 'faq.car_a5'),
    _FaqItem('faq.car_q6', 'faq.car_a6'),
  ]),
  _FaqSection('faq.section_community', Icons.groups_outlined, [
    _FaqItem('faq.community_q1', 'faq.community_a1'),
    _FaqItem('faq.community_q2', 'faq.community_a2'),
    _FaqItem('faq.community_q3', 'faq.community_a3'),
    _FaqItem('faq.community_q4', 'faq.community_a4'),
    _FaqItem('faq.community_q5', 'faq.community_a5'),
  ]),
  _FaqSection('faq.section_safety', Icons.shield_outlined, [
    _FaqItem('faq.safety_q1', 'faq.safety_a1'),
    _FaqItem('faq.safety_q2', 'faq.safety_a2'),
    _FaqItem('faq.safety_q3', 'faq.safety_a3'),
  ]),
  _FaqSection('faq.section_premium', Icons.workspace_premium_outlined, [
    _FaqItem('faq.premium_q1', 'faq.premium_a1'),
    _FaqItem('faq.premium_q2', 'faq.premium_a2'),
  ]),
  _FaqSection('faq.section_settings', Icons.settings_outlined, [
    _FaqItem('faq.settings_q1', 'faq.settings_a1'),
    _FaqItem('faq.settings_q2', 'faq.settings_a2'),
    _FaqItem('faq.settings_q3', 'faq.settings_a3'),
    _FaqItem('faq.settings_q4', 'faq.settings_a4'),
  ]),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('faq.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/settings.jpg'),
          Theme(
            data: AppTheme.dark,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.blue.withOpacity(0.14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: AppColors.blue),
                    title: Text(context.t('faq.guide_card_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(context.t('faq.guide_card_subtitle')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppGuideScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('faq.header'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (final section in _faqSections) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(section.icon, color: AppColors.blue),
                        title: Text(context.t(section.titleKey), style: const TextStyle(fontWeight: FontWeight.w600)),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: [
                          for (final item in section.items)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.t(item.questionKey), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(context.t(item.answerKey), style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark, height: 1.4)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
