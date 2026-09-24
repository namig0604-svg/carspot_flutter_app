/// Obshie nastroyki karty.
///
/// Tayly - CartoDB Dark Matter (temnaya tema, postroena na dannyh
/// OpenStreetMap). Ranshe byl svetlyy standartnyy OSM-tayl-server,
/// no vizual prilozheniya perevели na temnuyu temu (sm. theme/app_theme.dart),
/// i svetlaya karta na temnom fone vyglyadela chuzherodno - poetomu tayly
/// tozhe temnye, edinyy stil kak v prilozheniyah-referensah.
///
/// CartoDB - besplatnyy publichnyy servis dlya nebolshoy nagruzki, trebuet
/// atributsiyu OpenStreetMap + CARTO (sm. osmAttribution nizhe).
/// https://github.com/CartoDB/basemap-styles
///
/// Ranshe zdes byli neofitsialnye tayly Yandeks.Kart, no vyyasnilos, chto
/// etot sposob otdayet tayly NE po realnym geograficheskim koordinatam
/// (provereno: tayl dlya koordinat tsentra Tbilisi i tayl dlya koordinat
/// Krasnoy ploshchadi v Moskve po standartnoy formule z/x/y oba raza
/// pokazyvali sluchaynuyu neprichastnuyu mestnost) - iz-za etogo metki na
/// karte (skhodki, avtoservisy) okazyvalis smeshcheny v sluchaynye mesta,
/// vplot do gor.
///
/// Esli ponadobitsya tochnyy firmennyy vid Yandeks.Kart - edinstvennyy
/// nadezhnyy put eto ofitsialnyy yandex_mapkit s API-klyuchom (potrebuet
/// klyuch na yandex.ru/dev i nativnuyu nastroyku pod Android/iOS).
import 'package:latlong2/latlong.dart';

const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Temnye tayly CartoDB Dark Matter. {s} - poddomen (balansirovka nagruzki),
/// podstavlyaetsya flutter_map iz spiska tileSubdomains.
const String darkTileUrlTemplate =
    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

/// Aktivnyy istochnik taylov karty - ispolzuetsya vo vseh ekranah s kartoy.
const String activeTileUrlTemplate = darkTileUrlTemplate;

/// Poddomeny dlya activeTileUrlTemplate (nuzhny CartoDB, OSM ih ne trebuet
/// no ignoriruet lishniy parametr bez vreda).
const List<String> tileSubdomains = ['a', 'b', 'c', 'd'];

const String osmAttribution = '© OpenStreetMap contributors © CARTO';
const String mapUserAgentPackageName = 'com.carspot.app';

/// Tbilisi - to zhe znachenie, chto ranshe bylo zahardkozheno pri sozdanii skhodki.
const LatLng defaultMapCenter = LatLng(41.7151, 44.7671);

const double defaultMapZoom = 12.0;
const double worldMapZoom = 3.0;
