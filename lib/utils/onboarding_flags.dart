/// Ключи SharedPreferences для интерактивного тура по приложению
/// (см. lib/widgets/onboarding_tour.dart).
///
/// Флаг [kShouldShowOnboardingTourPrefsKey] взводится РОВНО один раз — в
/// момент, когда whats_new_dialog.dart обнаруживает, что это самая первая
/// установка приложения (ещё не сохранена ни одна версия, см.
/// checkAndShowWhatsNew). Экран HomeScreen проверяет этот флаг после
/// первого кадра и, если он взведён, запускает тур поверх реальных
/// элементов интерфейса, сразу же сбрасывая флаг — чтобы тур показался
/// ровно один раз новому пользователю, а не всем существующим при
/// обновлении приложения на версию с этой фичей.
const String kShouldShowOnboardingTourPrefsKey = 'should_show_onboarding_tour_v1';
