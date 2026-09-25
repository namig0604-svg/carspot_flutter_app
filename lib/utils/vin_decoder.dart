/// Простой офлайн-декодер VIN: страна/регион производителя, проверка контрольной
/// суммы (стандарт ISO 3779, работает для VIN североамериканского образца),
/// примерный год выпуска по 10-й позиции.
///
/// ВАЖНО: это НЕ полная проверка истории (ДТП, залоги, пробег) — для этого
/// нужен платный сторонний сервис/официальный API, см. VIN_LIMITATIONS ниже.
library vin_decoder;

class VinDecodeResult {
  final String vin;
  final bool formatValid;
  final bool? checksumValid; // null — если для этой VIN чек-сумма не применяется
  final String? countryRegion;
  final String? manufacturerHint;
  final int? approximateYear;
  final List<String> warnings;

  VinDecodeResult({
    required this.vin,
    required this.formatValid,
    this.checksumValid,
    this.countryRegion,
    this.manufacturerHint,
    this.approximateYear,
    this.warnings = const [],
  });
}

const String vinLimitationsNote =
    'Это базовая офлайн-расшифровка (страна, примерный год, формат). '
    'Полную историю — пробег, ДТП, залоги, число владельцев — так проверить нельзя: '
    'для этого нужен платный агрегатор (например Автотека, Автокод) или официальная база.';

// WMI (первые 1-3 символа) → регион/страна, упрощённая таблица самых частых.
const Map<String, String> _wmiCountry = {
  '1': 'США', '4': 'США', '5': 'США',
  '2': 'Канада',
  '3': 'Мексика',
  'J': 'Япония',
  'K': 'Корея',
  'L': 'Китай',
  'S': 'Великобритания',
  'V': 'Франция/Испания',
  'W': 'Германия',
  'X': 'Россия/СНГ',
  'Y': 'Швеция/Финляндия',
  'Z': 'Италия',
};

const Map<String, String> _wmiBrandHint = {
  'WVW': 'Volkswagen', 'WAU': 'Audi', 'WBA': 'BMW', 'WDB': 'Mercedes-Benz', 'WDD': 'Mercedes-Benz',
  'JHM': 'Honda', 'JTD': 'Toyota', 'JN1': 'Nissan', 'JM1': 'Mazda',
  'KMH': 'Hyundai', 'KNA': 'Kia',
  '1FA': 'Ford', '1FT': 'Ford', '1G1': 'Chevrolet', '1GC': 'Chevrolet',
  'XTA': 'ВАЗ/Lada', 'XW8': 'Volkswagen (РФ)', 'X7L': 'Hyundai (РФ)',
  'VF1': 'Renault', 'VF3': 'Peugeot', 'VF7': 'Citroën',
  'ZFA': 'Fiat', 'ZAR': 'Alfa Romeo',
};

// 10-я позиция VIN → модельный год (стандартный цикл на 30 лет, с 1980).
const Map<String, int> _yearCode = {
  'A': 1980, 'B': 1981, 'C': 1982, 'D': 1983, 'E': 1984, 'F': 1985, 'G': 1986, 'H': 1987,
  'J': 1988, 'K': 1989, 'L': 1990, 'M': 1991, 'N': 1992, 'P': 1993, 'R': 1994, 'S': 1995,
  'T': 1996, 'V': 1997, 'W': 1998, 'X': 1999, 'Y': 2000,
  '1': 2001, '2': 2002, '3': 2003, '4': 2004, '5': 2005, '6': 2006, '7': 2007, '8': 2008, '9': 2009,
};

const Map<String, int> _transliterate = {
  'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
  'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
  'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
};

const List<int> _weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

int? _charValue(String c) {
  if (RegExp(r'^[0-9]$').hasMatch(c)) return int.parse(c);
  return _transliterate[c];
}

VinDecodeResult decodeVin(String rawVin) {
  final vin = rawVin.trim().toUpperCase();
  final warnings = <String>[];

  if (vin.length != 17 || !RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(vin)) {
    return VinDecodeResult(
      vin: vin,
      formatValid: false,
      warnings: const ['VIN должен собтоять из 17 символов (без I, O, Q).'],
    );
  }

  // Проверка контрольной суммы (позиция 9) — по стандарту достоверна в основном
  // для VIN североамериканского формата, для остальных регионов носит справочный характер.
  bool? checksumValid;
  try {
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      final v = _charValue(vin[i]);
      if (v == null) {
        checksumValid = null;
        break;
      }
      sum += v * _weights[i];
    }
    if (checksumValid == null) {
      // не смогли посчитать
    } else {
      final remainder = sum % 11;
      final expected = remainder == 10 ? 'X' : remainder.toString();
      checksumValid = vin[8] == expected;
    }
  } catch (_) {
    checksumValid = null;
  }

  final wmi3 = vin.substring(0, 3);
  final wmi1 = vin.substring(0, 1);
  final brandHint = _wmiBrandHint[wmi3];
  final country = _wmiCountry[wmi1];

  final yearChar = vin[9];
  final approximateYear = _yearCode[yearChar];

  if (checksumValid == false) {
    warnings.add('Контрольная сумма не сошлась — возможна опечатка при вводе или VIN не североамериканского стандарта.');
  }
  if (approximateYear != null) {
    warnings.add('Год определён по 30-летнему циклу — если авто старше ~2010, возможна ошибка на 30 лет, сверяйте по ПТС.');
  }

  return VinDecodeResult(
    vin: vin,
    formatValid: true,
    checksumValid: checksumValid,
    countryRegion: country,
    manufacturerHint: brandHint,
    approximateYear: approximateYear,
    warnings: warnings,
  );
}
