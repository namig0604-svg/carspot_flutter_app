/// Метка/иконка для goal_type сезонного челленджа — значения должны совпадать
/// с GOAL_TYPES на бэкенде (app/models/challenge.py), иначе неизвестный тип
/// покажется как есть (см. challengeGoalLabel).
import 'package:flutter/material.dart';
import '../l10n/l10n_extensions.dart';

class ChallengeGoalOption {
  final String value;
  final String labelKey;
  final IconData icon;
  const ChallengeGoalOption(this.value, this.labelKey, this.icon);
}

const List<ChallengeGoalOption> challengeGoalOptions = [
  ChallengeGoalOption('attend_events', 'challenges.goal_attend_events', Icons.event_available),
  ChallengeGoalOption('create_events', 'challenges.goal_create_events', Icons.add_location_alt),
  ChallengeGoalOption('add_cars', 'challenges.goal_add_cars', Icons.directions_car),
  ChallengeGoalOption('rate_events', 'challenges.goal_rate_events', Icons.star_rate),
];

ChallengeGoalOption? _byValue(String? value) {
  for (final o in challengeGoalOptions) {
    if (o.value == value) return o;
  }
  return null;
}

String challengeGoalLabel(BuildContext context, String? goalType) {
  final option = _byValue(goalType);
  return option != null ? context.t(option.labelKey) : (goalType ?? '');
}

IconData challengeGoalIcon(String? goalType) => _byValue(goalType)?.icon ?? Icons.flag;
