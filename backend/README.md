# Nobetci Backend

NestJS tabanli backend servisidir. Sehirlerin eczaci odasi sayfalarindan veriyi ceker, normalize eder, Postgres'e yazar ve Flutter uygulamasina REST API sunar.

## Kurulum

```bash
npm install
cp .env.example .env
npm run start:dev
```

## Ortam Degiskenleri

- `PORT`
- `DB_TYPE`
- `DATABASE_URL`
- `GEOCODING_USER_AGENT`

## Endpointler

- `GET /cities`
- `GET /districts?city=istanbul`
- `GET /pharmacies/on-duty?city=istanbul`
- `GET /pharmacies/nearby?city=istanbul&lat=40.99&lng=29.03`

## Scheduler

Servis veriyi gunde 3 kez yeniler:

- 06:00
- 12:00
- 18:00

## Local Smoke Test Notu

Postgres kurulu degilse `.env` icinde `DB_TYPE=sqljs` ile servis dosya tabanli yerel veritabaninda acilabilir.
