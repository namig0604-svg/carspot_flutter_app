/// Obshie nastroyki karty.
///
/// Tayly - Mapbox (fungovye stili dark-v11/light-v11), tochno tot zhe
/// minimalistichnyy brendirovanny vid, chto na skrinshotah-referensah.
/// Publichny token nizhe - eto NE parol, Mapbox publichnye tokeny
/// specialno prednaznacheny dlya vstraivaniya v klientskie prilozheniya
/// (ogranicheny po scope - tolko chtenie taylov), besplatny limit -
/// 50 000 zagruzok karty v mesyats.
///
/// Do etogo byl CartoDB Dark Matter/Positron (besplatno, bez registratsii,
/// no menee stilizovanny vid), a eshche ranshe - neofitsialnye tayly
/// Yandeks.Kart, kotorye vyyasnilos otdavali tayly NE po realnym
/// geograficheskim koordinatam (provereno na dvuh izvestnyh tochkah:
/// Tbilisi i Moskva oba raza pokazyvali sluchaynuyu neprichastnuyu
/// mestnost) - iz-za etogo metki na karte okazyvalis smeshcheny vplot do
/// gor. S Mapbox etoy problemy net - standartny Web Mercator z/x/y.
import 'package:latlong2/latlong.dart';

const String osmTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Publichny token Mapbox (pk.xxx) - bezopasno hranit pryamo v kode,
/// eto ne sekret, a klyuch, prednaznachenny imenno dlya klientskih prilozheniy.
const String mapboxAccessToken =
    'pk.eyJ1IjoibmFtaWciLCJhIjoiY211ZnJ1Y3BuMGtjZjJ5czV2cGZmNHZ6ZCJ9.iJFks2TeZMc0AajFmzAEXA';

/// Temnyy firmenny stil Mapbox - osnovnaya karta prilozheniya.
const String darkTileUrlTemplate =
    'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken';

/// Svetlyy firmenny stil Mapbox - dlya perekluchatelya temy karty
/// (Temnaya/Svetlaya/Avto) na ekranah karty.
const String lightTileUrlTemplate =
    'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken';

/// Aktivnyy istochnik taylov karty - ispolzuetsya vo vseh ekranah s kartoy.
const String activeTileUrlTemplate = darkTileUrlTemplate;

/// U Mapbox odin host (api.mapbox.com), poddomeny {s} ne nuzhny - v otlichie
/// ot CartoDB/OSM. Ostavlyaem pustym spiskom, TileLayer prosto ne budet
/// nichego podstavlyat.
const List<String> tileSubdomains = [];

const String osmAttribution = '© Mapbox © OpenStreetMap contributors';
const String mapUserAgentPackageName = 'com.carspot.app';

/// Tbilisi - to zhe znachenie, chto ranshe bylo zahardkozheno pri sozdanii skhodki.
const LatLng defaultMapCenter = LatLng(41.7151, 44.7671);

const double defaultMapZoom = 12.0;
const double worldMapZoom = 3.0;
