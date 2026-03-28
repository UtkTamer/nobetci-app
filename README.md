# Nobetci App

Nobetci App, yakındaki nobetci eczaneleri harita ve alt liste deneyimiyle gosteren bir Flutter prototipidir.

## Ozellikler

- Harita uzerinde nobetci eczaneleri marker olarak gosterir.
- Alttaki eczane panelinde arama ve detay acma deneyimi sunar.
- Haritadan bir eczane secildiginde alt panel buyur ve ilgili eczanenin detaylari acilir.
- Konum butonu ile kullanicinin mevcut konumu merkeze alinir.
- Kullanicinin mevcut konumu harita uzerinde nokta olarak gosterilir.
- Eczane kartlari icinden arama, arama ve yol tarifi aksiyonlari sunulur.

## Teknolojiler

- Flutter
- flutter_map
- geolocator
- url_launcher

## Proje Yapisi

- `lib/features/home`: ana ekran, harita ve ust seviye etkileşimler
- `lib/features/pharmacies`: eczane domain modeli, mock veri ve liste/panel bilesenleri
- `lib/core`: sabitler, yardimci servisler ve ortak utility katmani
- `test`: widget testleri

## Calistirma

```bash
/Users/utkusair/flutter/bin/flutter pub get
/Users/utkusair/flutter/bin/flutter run
```

## Test ve Analiz

```bash
/Users/utkusair/flutter/bin/flutter test
/Users/utkusair/flutter/bin/flutter analyze
```

## Notlar

- Konum ozelligi icin cihaz veya simulatorde konum izni verilmelidir.
- Harita marker secimi ve konum butonu davranislari widget testleri ile dogrulanmistir.
