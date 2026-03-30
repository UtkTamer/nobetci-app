# Nobetci App

Nobetci App, yakındaki nobetci eczaneleri harita ve alt liste deneyimiyle gosteren Flutter istemcisi ve onu besleyen NestJS backend iskeletinden olusan bir projedir.

## Ozellikler

- Harita uzerinde nobetci eczaneleri marker olarak gosterir.
- Alttaki eczane panelinde arama ve detay acma deneyimi sunar.
- Haritadan bir eczane secildiginde alt panel buyur ve ilgili eczanenin detaylari acilir.
- Konum butonu ile kullanicinin mevcut konumu merkeze alinir.
- Kullanicinin mevcut konumu harita uzerinde nokta olarak gosterilir.
- Eczane kartlari icinden arama, arama ve yol tarifi aksiyonlari sunulur.
- Sehir listesini backend API'den alir ve guncel nobetci eczane verisini uzaktan yukler.
- Son guncelleme zamani, stale veri durumu, loading ve error durumlarini gosterir.

## Teknolojiler

- Flutter
- NestJS
- Postgres
- flutter_map
- geolocator
- http
- url_launcher

## Proje Yapisi

- `lib/features/home`: ana ekran, harita ve ust seviye etkileşimler
- `lib/features/pharmacies`: eczane domain modeli, remote repository ve liste/panel bilesenleri
- `lib/core`: sabitler, yardimci servisler ve ortak utility katmani
- `backend`: kaynak adaptorleri, scheduler, normalize katmani ve REST API
- `test`: widget testleri

## Calistirma

```bash
/Users/utkusair/flutter/bin/flutter pub get
/Users/utkusair/flutter/bin/flutter run --dart-define=NOBETCI_API_BASE_URL=http://localhost:3000
```

## Test ve Analiz

```bash
/Users/utkusair/flutter/bin/flutter test
/Users/utkusair/flutter/bin/flutter analyze
```

## Backend

Backend servisi ayri klasorde bulunur:

```bash
cd backend
npm install
cp .env.example .env
npm run start:dev
```

## Notlar

- Konum ozelligi icin cihaz veya simulatorde konum izni verilmelidir.
- Harita marker secimi ve konum butonu davranislari widget testleri ile dogrulanmistir.
- Flutter uygulamasi backend adresini `--dart-define=NOBETCI_API_BASE_URL=...` ile alir.
