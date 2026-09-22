/// Датасет марок и моделей машин + типы КПП и топлива для car_form_screen.
///
/// Список ориентирован на страны СНГ и Грузию: глобальные бренды + отдельные
/// марки, характерные для региона (Lada/ВАЗ, УАЗ, ГАЗ, Москвич, китайские бренды).
library car_data;

/// Ярлык для варианта "марки нет в списке" в UI пикера.
const String kOtherBrandLabel = 'Другая марка';

/// Марка -> список известных моделей.
const Map<String, List<String>> kCarModelsByBrand = {
  'Acura': ['MDX', 'TLX', 'RDX', 'ILX'],
  'Alfa Romeo': ['Giulia', 'Stelvio', '147', '156'],
  'Aston Martin': ['DB11', 'Vantage', 'DBS', 'DBX'],
  'Audi': ['A3', 'A4', 'A6', 'A8', 'Q3', 'Q5', 'Q7', 'Q8', 'A5', 'A7', 'TT', 'RS6', 'e-tron'],
  'BMW': ['3 Series', '5 Series', '7 Series', 'X1', 'X3', 'X5', 'X6', '1 Series', '2 Series', '4 Series', '6 Series', 'M3', 'M5', 'i3', 'i4', 'iX'],
  'BYD': ['Song Plus', 'Han', 'Atto 3', 'Tang', 'Seal', 'Qin'],
  'Bentley': ['Continental GT', 'Bentayga', 'Flying Spur', 'Mulsanne'],
  'Buick': ['Enclave', 'Encore', 'LaCrosse'],
  'Cadillac': ['Escalade', 'CTS', 'SRX', 'XT5'],
  'Changan': ['CS35', 'CS55', 'CS75', 'Eado', 'UNI-T'],
  'Chery': ['Tiggo 4', 'Tiggo 7', 'Tiggo 8', 'Arrizo 5', 'Amulet', 'Bonus', 'QQ'],
  'Chevrolet': ['Cruze', 'Aveo', 'Lacetti', 'Cobalt', 'Niva', 'Nexia', 'Spark', 'Trailblazer', 'Captiva', 'Tahoe', 'Camaro', 'Malibu', 'Epica'],
  'Chrysler': ['300C', 'Pacifica', 'Voyager'],
  'Citroen': ['C4', 'C5', 'C3', 'Berlingo', 'Xsara', 'C-Elysee', 'Jumpy'],
  'Daewoo': ['Nexia', 'Matiz', 'Lanos', 'Gentra'],
  'Datsun': ['on-DO', 'mi-DO'],
  'Dodge': ['Charger', 'Challenger', 'Journey', 'Ram'],
  'Exeed': ['TXL', 'LX', 'VX'],
  'Ferrari': ['488', 'F8 Tributo', 'Roma', 'Portofino', '812', 'SF90'],
  'Fiat': ['Albea', 'Linea', 'Punto', 'Doblo', '500'],
  'Ford': ['Focus', 'Fiesta', 'Mondeo', 'Kuga', 'Explorer', 'Ranger', 'Transit', 'EcoSport', 'Fusion', 'Escape', 'Edge', 'Mustang'],
  'GAZ': ['Volga', 'Gazelle', 'Sobol', '3110'],
  'GMC': ['Yukon', 'Sierra', 'Terrain'],
  'Geely': ['Coolray', 'Atlas', 'Emgrand', 'Monjaro', 'Tugella', 'Okavango'],
  'Genesis': ['G70', 'G80', 'G90', 'GV70', 'GV80'],
  'Great Wall': ['Poer', 'Hover H5', 'Wingle', 'Voleex'],
  'Haval': ['Jolion', 'F7', 'H6', 'Dargo', 'M6'],
  'Honda': ['Civic', 'Accord', 'CR-V', 'Fit', 'Pilot', 'HR-V', 'Odyssey', 'Stepwgn', 'Stream', 'Integra', 'Insight'],
  'Hyundai': ['Solaris', 'Elantra', 'Sonata', 'Tucson', 'Santa Fe', 'Accent', 'Creta', 'i30', 'Getz', 'Matrix', 'Starex', 'Palisade', 'Kona'],
  'Infiniti': ['Q50', 'QX50', 'QX60', 'FX35', 'G35'],
  'Isuzu': ['D-Max', 'MU-X', 'Trooper'],
  'Jaguar': ['XE', 'XF', 'XJ', 'F-Pace', 'E-Pace', 'F-Type'],
  'Jeep': ['Grand Cherokee', 'Cherokee', 'Wrangler', 'Compass', 'Renegade', 'Patriot'],
  'Kia': ['Rio', 'Cerato', 'Optima', 'Sportage', 'Sorento', 'Ceed', 'Picanto', 'Soul', 'Mohave', 'Spectra', 'Seltos', 'K5'],
  'Lada (ВАЗ)': ['Granta', 'Vesta', 'Kalina', 'Priora', '2107', '2114', '2110', 'Niva', 'Largus', 'XRAY', '4x4'],
  'Lamborghini': ['Huracan', 'Aventador', 'Urus'],
  'Land Rover': ['Range Rover', 'Range Rover Sport', 'Range Rover Evoque', 'Discovery', 'Discovery Sport', 'Defender', 'Freelander'],
  'Lexus': ['RX', 'ES', 'GX', 'LX', 'NX', 'IS', 'LS', 'UX', 'LC'],
  'Lincoln': ['Navigator', 'Continental', 'MKZ'],
  'Maserati': ['Ghibli', 'Quattroporte', 'Levante', 'GranTurismo'],
  'Mazda': ['3', '6', 'CX-5', 'CX-3', 'CX-9', 'MX-5', 'Demio', 'Familia', 'Premacy', 'CX-30'],
  'Mercedes-Benz': ['C-Class', 'E-Class', 'S-Class', 'GLA', 'GLC', 'GLE', 'GLS', 'A-Class', 'CLA', 'G-Class', 'Vito', 'Sprinter', 'CLS', 'ML'],
  'Mini': ['Cooper', 'Countryman', 'Clubman', 'One'],
  'Mitsubishi': ['Lancer', 'Outlander', 'ASX', 'Pajero', 'Galant', 'Colt', 'L200', 'Eclipse Cross'],
  'Moskvich': ['412', '2141', '3'],
  'Nissan': ['Almera', 'Qashqai', 'X-Trail', 'Juke', 'Note', 'Teana', 'Primera', 'Patrol', 'Navara', 'Murano', 'Tiida', 'Sentra', 'Skyline', 'GT-R', 'Micra'],
  'Omoda': ['C5', 'S5'],
  'Opel': ['Astra', 'Corsa', 'Insignia', 'Zafira', 'Vectra', 'Mokka', 'Antara', 'Meriva'],
  'Peugeot': ['308', '408', '3008', '508', '206', '207', '406', '2008', '5008', 'Partner'],
  'Porsche': ['911', 'Cayenne', 'Panamera', 'Macan', 'Boxster', 'Cayman', 'Taycan'],
  'Renault': ['Logan', 'Sandero', 'Duster', 'Megane', 'Fluence', 'Clio', 'Koleos', 'Kaptur', 'Symbol', 'Scenic'],
  'Rolls-Royce': ['Phantom', 'Ghost', 'Cullinan', 'Wraith'],
  'Rover': ['75', '45', '25'],
  'Saab': ['9-3', '9-5'],
  'Seat': ['Leon', 'Ibiza', 'Toledo', 'Alhambra'],
  'Skoda': ['Octavia', 'Rapid', 'Superb', 'Fabia', 'Yeti', 'Kodiaq', 'Karoq', 'Kamiq'],
  'Smart': ['Fortwo', 'Forfour'],
  'SsangYong': ['Actyon', 'Kyron', 'Rexton', 'Korando'],
  'Subaru': ['Forester', 'Impreza', 'Legacy', 'Outback', 'XV', 'WRX', 'Tribeca'],
  'Suzuki': ['Grand Vitara', 'Swift', 'SX4', 'Jimny', 'Vitara'],
  'Tank': ['300', '500'],
  'Tesla': ['Model 3', 'Model S', 'Model X', 'Model Y'],
  'Toyota': ['Corolla', 'Camry', 'RAV4', 'Land Cruiser', 'Land Cruiser Prado', 'Hilux', 'Yaris', 'Avensis', 'Highlander', 'C-HR', 'Fortuner', 'Prius', 'Auris', 'Vitz', 'Mark II', 'Chaser', 'Crown', 'Supra', 'Alphard'],
  'UAZ': ['Patriot', 'Hunter', 'Buhanka (452)', 'Pickup'],
  'Volkswagen': ['Golf', 'Polo', 'Passat', 'Tiguan', 'Jetta', 'Touareg', 'Touran', 'Caddy', 'Transporter', 'Amarok', 'Arteon', 'Multivan'],
  'Volvo': ['S60', 'S80', 'V40', 'V60', 'V70', 'XC60', 'XC90', 'XC40', 'S90'],
  'Zeekr': ['001', '007', 'X'],
};

/// Типы коробки передач.
const List<String> kTransmissionTypes = ['Механика', 'Автомат', 'Робот', 'Вариатор'];

/// Типы топлива.
const List<String> kFuelTypes = ['Бензин', 'Дизель', 'Гибрид', 'Электро', 'Газ'];

/// Типы кузова.
const List<String> kBodyTypes = [
  'Седан',
  'Хэтчбек',
  'Универсал',
  'Купе',
  'Кабриолет',
  'Внедорожник (SUV)',
  'Кроссовер',
  'Минивэн',
  'Пикап',
  'Лифтбек',
  'Фургон',
];

/// Годы выпуска для пикера — от следующего модельного года вниз до 1960.
/// Не const (нужен DateTime.now()), но вычисляется один раз при старте.
final int _kCurrentYear = DateTime.now().year;
final List<String> kCarYears = List.generate(
  _kCurrentYear + 1 - 1960 + 1,
  (i) => (_kCurrentYear + 1 - i).toString(),
);

