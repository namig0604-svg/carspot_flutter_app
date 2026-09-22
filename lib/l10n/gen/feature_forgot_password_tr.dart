/// Переводы для экрана восстановления пароля (forgot_password_screen.dart)
/// и ссылки на него с экрана логина (login_screen.dart).
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureForgotPasswordTranslations = {
  // ────────────────────── forgot_password_screen.dart ──────────────────────
  'forgot_password.title': {'ru': 'Восстановление пароля', 'en': 'Reset password', 'ka': 'პაროლის აღდგენა'},
  'forgot_password.subtitle_step1': {
    'ru': 'Введите email, указанный при регистрации — если он есть в системе, на него придёт код для сброса пароля.',
    'en': 'Enter the email you registered with — if it exists in our system, we will send a code to reset your password.',
    'ka': 'შეიყვანეთ ელფოსტა, რომლითაც დარეგისტრირდით — თუ ის სისტემაშია, გამოგეგზავნებათ პაროლის აღდგენის კოდი.',
  },
  'forgot_password.subtitle_step2': {
    'ru': 'Если {email} есть в системе, на него отправлен 6-значный код. Введите его и новый пароль ниже.',
    'en': 'If {email} is in our system, a 6-digit code has been sent to it. Enter it and your new password below.',
    'ka': 'თუ {email} სისტემაშია, მასზე გამოგზავნილია 6-ნიშნა კოდი. შეიყვანეთ ის და ახალი პაროლი ქვემოთ.',
  },
  'forgot_password.email_label': {'ru': 'Email', 'en': 'Email', 'ka': 'ელფოსტა'},
  'forgot_password.send_code_button': {'ru': 'Отправить код', 'en': 'Send code', 'ka': 'კოდის გაგზავნა'},
  'forgot_password.code_label': {'ru': 'Код из письма', 'en': 'Code from email', 'ka': 'კოდი ელფოსტიდან'},
  'forgot_password.new_password_label': {'ru': 'Новый пароль', 'en': 'New password', 'ka': 'ახალი პაროლი'},
  'forgot_password.confirm_password_label': {
    'ru': 'Повторите новый пароль',
    'en': 'Confirm new password',
    'ka': 'გაიმეორეთ ახალი პაროლი',
  },
  'forgot_password.reset_button': {'ru': 'Сохранить новый пароль', 'en': 'Reset password', 'ka': 'პაროლის შენახვა'},
  'forgot_password.passwords_dont_match': {
    'ru': 'Пароли не совпадают',
    'en': 'Passwords do not match',
    'ka': 'პაროლები არ ემთხვევა',
  },
  'forgot_password.resend_code': {'ru': 'Отправить код ещё раз', 'en': 'Resend code', 'ka': 'კოდის ხელახლა გაგზავნა'},
  'forgot_password.generic_sent_message': {
    'ru': 'Если такой email есть в системе, мы отправили на него код',
    'en': 'If this email exists in our system, we have sent a code to it',
    'ka': 'თუ ასეთი ელფოსტა სისტემაშია, კოდი გამოგზავნილია მასზე',
  },
  'forgot_password.success_message': {
    'ru': 'Пароль успешно изменён. Теперь вы можете войти с новым паролем.',
    'en': 'Password changed successfully. You can now log in with your new password.',
    'ka': 'პაროლი წარმატებით შეიცვალა. ახლა შეგიძლიათ შეხვიდეთ ახალი პაროლით.',
  },
  'forgot_password.error_message': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},

  // ────────────────────────── login_screen.dart ────────────────────────────
  'login.forgot_password_link': {'ru': 'Забыли пароль?', 'en': 'Forgot password?', 'ka': 'დაგავიწყდათ პაროლი?'},
};
