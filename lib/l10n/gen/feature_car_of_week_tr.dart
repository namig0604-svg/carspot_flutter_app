/// Голосование «Машина недели» — car_of_week_screen.dart. Только ru/en/ka —
/// остальные языки (az/hy/kk/uk) откатываются на русский. Подключается
/// централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureCarOfWeekTranslations = {
  'car_of_week.title': {'ru': 'Машина недели', 'en': 'Car of the week', 'ka': 'კვირის მანქანა'},
  'home.menu_car_of_week': {'ru': 'Машина недели', 'en': 'Car of the week', 'ka': 'კვირის მანქანა'},
  'car_of_week.empty': {
    'ru': 'Пока никто не выставил машину на голосование этой недели',
    'en': 'No one has nominated a car for this week yet',
    'ka': 'ჯერ არავის გამოუტანია მანქანა ამ კვირის კენჭისყრაზე',
  },
  'car_of_week.winner_banner_title': {
    'ru': 'Победитель прошлой недели',
    'en': "Last week's winner",
    'ka': 'გასული კვირის გამარჯვებული',
  },
  'car_of_week.nominate_button': {'ru': 'Выставить машину', 'en': 'Nominate a car', 'ka': 'მანქანის გამოტანა'},
  'car_of_week.nominate_dialog_title': {'ru': 'Выберите машину', 'en': 'Choose a car', 'ka': 'აირჩიეთ მანქანა'},
  'car_of_week.nominate_submit': {'ru': 'Выставить', 'en': 'Nominate', 'ka': 'გამოტანა'},
  'car_of_week.self_entry_label': {'ru': 'Ваша заявка', 'en': 'Your entry', 'ka': 'თქვენი განაცხადი'},
  'car_of_week.votes_label': {'ru': 'Голосов: {count}', 'en': 'Votes: {count}', 'ka': 'ხმები: {count}'},
  'car_of_week.delete_confirm_title': {
    'ru': 'Снять машину с голосования?',
    'en': 'Withdraw this car from voting?',
    'ka': 'მანქანის კენჭისყრიდან მოხსნა?',
  },
};
