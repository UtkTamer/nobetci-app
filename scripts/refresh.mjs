import axios from 'axios';
import { createHash } from 'crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const CITIES = [
  { slug: 'adana', displayName: 'Adana', plateCode: '1' },
  { slug: 'adiyaman', displayName: 'Adıyaman', plateCode: '2' },
  { slug: 'afyonkarahisar', displayName: 'Afyonkarahisar', plateCode: '3' },
  { slug: 'agri', displayName: 'Ağrı', plateCode: '4' },
  { slug: 'amasya', displayName: 'Amasya', plateCode: '5' },
  { slug: 'ankara', displayName: 'Ankara', plateCode: '6' },
  { slug: 'antalya', displayName: 'Antalya', plateCode: '7' },
  { slug: 'artvin', displayName: 'Artvin', plateCode: '8' },
  { slug: 'aydin', displayName: 'Aydın', plateCode: '9' },
  { slug: 'balikesir', displayName: 'Balıkesir', plateCode: '10' },
  { slug: 'bilecik', displayName: 'Bilecik', plateCode: '11' },
  { slug: 'bingol', displayName: 'Bingöl', plateCode: '12' },
  { slug: 'bitlis', displayName: 'Bitlis', plateCode: '13' },
  { slug: 'bolu', displayName: 'Bolu', plateCode: '14' },
  { slug: 'burdur', displayName: 'Burdur', plateCode: '15' },
  { slug: 'bursa', displayName: 'Bursa', plateCode: '16' },
  { slug: 'canakkale', displayName: 'Çanakkale', plateCode: '17' },
  { slug: 'cankiri', displayName: 'Çankırı', plateCode: '18' },
  { slug: 'corum', displayName: 'Çorum', plateCode: '19' },
  { slug: 'denizli', displayName: 'Denizli', plateCode: '20' },
  { slug: 'diyarbakir', displayName: 'Diyarbakır', plateCode: '21' },
  { slug: 'edirne', displayName: 'Edirne', plateCode: '22' },
  { slug: 'elazig', displayName: 'Elazığ', plateCode: '23' },
  { slug: 'erzincan', displayName: 'Erzincan', plateCode: '24' },
  { slug: 'erzurum', displayName: 'Erzurum', plateCode: '25' },
  { slug: 'eskisehir', displayName: 'Eskişehir', plateCode: '26' },
  { slug: 'gaziantep', displayName: 'Gaziantep', plateCode: '27' },
  { slug: 'giresun', displayName: 'Giresun', plateCode: '28' },
  { slug: 'gumushane', displayName: 'Gümüşhane', plateCode: '29' },
  { slug: 'hakkari', displayName: 'Hakkâri', plateCode: '30' },
  { slug: 'hatay', displayName: 'Hatay', plateCode: '31' },
  { slug: 'isparta', displayName: 'Isparta', plateCode: '32' },
  { slug: 'mersin', displayName: 'Mersin', plateCode: '33' },
  { slug: 'istanbul', displayName: 'İstanbul', plateCode: '34' },
  { slug: 'izmir', displayName: 'İzmir', plateCode: '35' },
  { slug: 'kars', displayName: 'Kars', plateCode: '36' },
  { slug: 'kastamonu', displayName: 'Kastamonu', plateCode: '37' },
  { slug: 'kayseri', displayName: 'Kayseri', plateCode: '38' },
  { slug: 'kirklareli', displayName: 'Kırklareli', plateCode: '39' },
  { slug: 'kirsehir', displayName: 'Kırşehir', plateCode: '40' },
  { slug: 'kocaeli', displayName: 'Kocaeli', plateCode: '41' },
  { slug: 'konya', displayName: 'Konya', plateCode: '42' },
  { slug: 'kutahya', displayName: 'Kütahya', plateCode: '43' },
  { slug: 'malatya', displayName: 'Malatya', plateCode: '44' },
  { slug: 'manisa', displayName: 'Manisa', plateCode: '45' },
  { slug: 'kahramanmaras', displayName: 'Kahramanmaraş', plateCode: '46' },
  { slug: 'mardin', displayName: 'Mardin', plateCode: '47' },
  { slug: 'mugla', displayName: 'Muğla', plateCode: '48' },
  { slug: 'mus', displayName: 'Muş', plateCode: '49' },
  { slug: 'nevsehir', displayName: 'Nevşehir', plateCode: '50' },
  { slug: 'nigde', displayName: 'Niğde', plateCode: '51' },
  { slug: 'ordu', displayName: 'Ordu', plateCode: '52' },
  { slug: 'rize', displayName: 'Rize', plateCode: '53' },
  { slug: 'sakarya', displayName: 'Sakarya', plateCode: '54' },
  { slug: 'samsun', displayName: 'Samsun', plateCode: '55' },
  { slug: 'siirt', displayName: 'Siirt', plateCode: '56' },
  { slug: 'sinop', displayName: 'Sinop', plateCode: '57' },
  { slug: 'sivas', displayName: 'Sivas', plateCode: '58' },
  { slug: 'tekirdag', displayName: 'Tekirdağ', plateCode: '59' },
  { slug: 'tokat', displayName: 'Tokat', plateCode: '60' },
  { slug: 'trabzon', displayName: 'Trabzon', plateCode: '61' },
  { slug: 'tunceli', displayName: 'Tunceli', plateCode: '62' },
  { slug: 'sanliurfa', displayName: 'Şanlıurfa', plateCode: '63' },
  { slug: 'usak', displayName: 'Uşak', plateCode: '64' },
  { slug: 'van', displayName: 'Van', plateCode: '65' },
  { slug: 'yozgat', displayName: 'Yozgat', plateCode: '66' },
  { slug: 'zonguldak', displayName: 'Zonguldak', plateCode: '67' },
  { slug: 'aksaray', displayName: 'Aksaray', plateCode: '68' },
  { slug: 'bayburt', displayName: 'Bayburt', plateCode: '69' },
  { slug: 'karaman', displayName: 'Karaman', plateCode: '70' },
  { slug: 'kirikkale', displayName: 'Kırıkkale', plateCode: '71' },
  { slug: 'batman', displayName: 'Batman', plateCode: '72' },
  { slug: 'sirnak', displayName: 'Şırnak', plateCode: '73' },
  { slug: 'bartin', displayName: 'Bartın', plateCode: '74' },
  { slug: 'ardahan', displayName: 'Ardahan', plateCode: '75' },
  { slug: 'igdir', displayName: 'Iğdır', plateCode: '76' },
  { slug: 'yalova', displayName: 'Yalova', plateCode: '77' },
  { slug: 'karabuk', displayName: 'Karabük', plateCode: '78' },
  { slug: 'kilis', displayName: 'Kilis', plateCode: '79' },
  { slug: 'osmaniye', displayName: 'Osmaniye', plateCode: '80' },
  { slug: 'duzce', displayName: 'Düzce', plateCode: '81' },
];

const SOURCE_BASE_URL = 'https://www.eczaneler.gen.tr';

const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/search';
const NOMINATIM_DELAY_MS = 1200;

const CONCURRENCY = 5;
const CITY_RETRY_ATTEMPTS = 2;
const CITY_RETRY_DELAY_MS = 5000;
const INTER_CITY_DELAY_MS = 1000;

const CACHE_PATH = resolve(__dirname, 'geocode-cache.json');
const OUTPUT_DIR = resolve(__dirname, '..', 'docs', 'api');

const DEFAULT_HEADERS = {
  Accept:
    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
  'User-Agent':
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
};

const selectedCitySlugs = (process.env.CITY_FILTER ?? '')
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean);
const skipGeocode = process.env.SKIP_GEOCODE === '1';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function generateId(name, district, city) {
  const input = `${name}|${district}|${city}`.toLocaleLowerCase('tr');
  return createHash('md5').update(input).digest('hex');
}

function formatDutyDate(date) {
  const formatter = new Intl.DateTimeFormat('tr-TR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'Europe/Istanbul',
  });
  const parts = formatter.formatToParts(date);
  const day = parts.find((p) => p.type === 'day')?.value ?? '';
  const month = parts.find((p) => p.type === 'month')?.value ?? '';
  const year = parts.find((p) => p.type === 'year')?.value ?? '';
  return `${day}/${month}/${year}`;
}

function cleanText(value) {
  return value.replace(/\s+/g, ' ').trim();
}

function cleanPhone(value) {
  return cleanText(value).replace(/\bAra\b/gi, '').trim();
}

function decodeHtml(value) {
  return value
    .replace(/&nbsp;/gi, ' ')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&quot;/gi, '"')
    .replace(/&amp;/gi, '&')
    .replace(/&uuml;/gi, 'ü')
    .replace(/&Uuml;/gi, 'Ü')
    .replace(/&ouml;/gi, 'ö')
    .replace(/&Ouml;/gi, 'Ö')
    .replace(/&ccedil;/gi, 'ç')
    .replace(/&Ccedil;/gi, 'Ç')
    .replace(/&scedil;/gi, 'ş')
    .replace(/&Scedil;/gi, 'Ş')
    .replace(/&raquo;/gi, '»')
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)));
}

function stripTags(value) {
  return cleanText(decodeHtml(value).replace(/<[^>]+>/g, ' '));
}

// ---------------------------------------------------------------------------
// Turkish address cleaning for Nominatim
// ---------------------------------------------------------------------------

function cleanTurkishAddress(raw) {
  let address = raw;

  // Remove building/apartment numbers
  address = address.replace(/\bNO\s*:\s*\S+/gi, '');
  address = address.replace(/\b(BLK|BLOK|KAT|D:|DAİRE)\s*\S*/gi, '');

  // Expand abbreviations
  address = address.replace(/\bMAH\.\s*/gi, 'Mahallesi ');
  address = address.replace(/\bMAH\b/gi, 'Mahallesi');
  address = address.replace(/\bCAD\.\s*/gi, 'Caddesi ');
  address = address.replace(/\bCAD\b/gi, 'Caddesi');
  address = address.replace(/\bSOK\.\s*/gi, 'Sokak ');
  address = address.replace(/\bSOK\b/gi, 'Sokak');
  address = address.replace(/\bSK\.\s*/gi, 'Sokak ');
  address = address.replace(/\bSK\b/gi, 'Sokak');
  address = address.replace(/\bBLV\.\s*/gi, 'Bulvarı ');
  address = address.replace(/\bBLV\b/gi, 'Bulvarı');
  address = address.replace(/\bMEV\.\s*/gi, 'Mevkii ');
  address = address.replace(/\bSİT\.\s*/gi, 'Sitesi ');

  // Title case
  address = address
    .toLocaleLowerCase('tr')
    .replace(/(^|\s)\S/g, (ch) => ch.toLocaleUpperCase('tr'));

  return address.replace(/\s+/g, ' ').trim();
}

// ---------------------------------------------------------------------------
// Geocode cache
// ---------------------------------------------------------------------------

let geocodeCache = {};

function loadCache() {
  try {
    geocodeCache = JSON.parse(readFileSync(CACHE_PATH, 'utf-8'));
    console.log(`  Geocode cache loaded: ${Object.keys(geocodeCache).length} entries`);
  } catch {
    geocodeCache = {};
  }
}

function saveCache() {
  writeFileSync(CACHE_PATH, JSON.stringify(geocodeCache, null, 2) + '\n');
}

let nominatimQueue = Promise.resolve();

async function nominatimQuery(query) {
  // Serialize all Nominatim calls to respect rate limit across concurrent workers
  const result = nominatimQueue.then(async () => {
    await sleep(NOMINATIM_DELAY_MS);

    const response = await axios.get(NOMINATIM_URL, {
      params: { q: query, format: 'jsonv2', limit: 1 },
      headers: { 'User-Agent': 'nobetci-app/1.0' },
    });

    const data = response.data[0];
    if (!data) return null;

    return { latitude: Number(data.lat), longitude: Number(data.lon) };
  });

  nominatimQueue = result.catch(() => {});
  return result;
}

function buildGeocodingQueries(rawAddress, district, city) {
  const cleaned = cleanTurkishAddress(rawAddress);
  const districtPart = district || '';

  // Extract mahalle name if present
  const mahalleMatch = cleaned.match(/(\S+\s+Mahallesi)/i);
  const mahalle = mahalleMatch?.[1] ?? '';

  const queries = [];

  // 1. Full cleaned address + district + city
  if (districtPart) {
    queries.push(`${cleaned}, ${districtPart}, ${city}, Türkiye`);
  }

  // 2. Just street name (remove mahalle) + district + city
  const withoutMahalle = cleaned.replace(/\S+\s+Mahallesi\s*/i, '').trim();
  if (withoutMahalle && districtPart) {
    queries.push(`${withoutMahalle}, ${districtPart}, ${city}, Türkiye`);
  }

  // 3. Mahalle + district + city
  if (mahalle && districtPart) {
    queries.push(`${mahalle}, ${districtPart}, ${city}, Türkiye`);
  }

  // 4. District + city (district center as last resort)
  if (districtPart) {
    queries.push(`${districtPart}, ${city}, Türkiye`);
  }

  return queries;
}

async function geocode(rawAddress, district, city) {
  const cacheKey = rawAddress.toLocaleLowerCase('tr').trim();
  if (geocodeCache[cacheKey]) return geocodeCache[cacheKey];

  const queries = buildGeocodingQueries(rawAddress, district, city);

  for (const query of queries) {
    try {
      const coords = await nominatimQuery(query);
      if (coords) {
        geocodeCache[cacheKey] = coords;
        return coords;
      }
    } catch {
      // Try next query
    }
  }

  return null;
}

// ---------------------------------------------------------------------------
// Eczaneler.gen.tr scraping
// ---------------------------------------------------------------------------

function extractTodayTabHtml(html) {
  const activeMatch = html.match(
    /<div class="tab-pane[^"]*show active[^"]*" id="nav-bugun"[\s\S]*?<\/table>\s*<\/div>/i,
  );
  if (activeMatch) {
    return activeMatch[0];
  }

  const fallbackMatch = html.match(
    /<div class="tab-pane[^"]*" id="nav-bugun"[\s\S]*?<\/table>\s*<\/div>/i,
  );
  return fallbackMatch?.[0] ?? '';
}

function extractDetailsHtml(rowHtml) {
  const match = rowHtml.match(
    /<div class=['"]col-lg-6['"]>([\s\S]*?)<\/div><div class=['"]col-lg-3 py-lg-2['"]>/i,
  );
  return match?.[1] ?? '';
}

function extractDistrict(detailsHtml) {
  const parts = [
    ...detailsHtml.matchAll(
      /<span class="[^"]*(?:bg-info|bg-secondary)[^"]*">([\s\S]*?)<\/span>/gi,
    ),
  ]
    .map((match) => stripTags(match[1]))
    .filter(Boolean)

  return parts.join(' ').trim();
}

function extractAddress(detailsHtml) {
  const addressHtml = detailsHtml
    .replace(/<div class="py-2">[\s\S]*?<\/div>/gi, ' ')
    .replace(/<div class="my-2">[\s\S]*?<\/div>/gi, ' ')
    .replace(/<br\s*\/?>/gi, ' ');

  return stripTags(addressHtml).replace(/\(\s*Akşam[^)]*\)/gi, '').trim();
}

function extractRecordsFromTab(tabHtml, citySlug) {
  const rowMatches = tabHtml.match(
    /<tr><td colspan="3" class="border-bottom">[\s\S]*?<\/td><\/tr>/gi,
  ) ?? [];

  return rowMatches
    .map((rowHtml) => {
      const detailsHtml = extractDetailsHtml(rowHtml);
      const sourcePath = rowHtml.match(/<a href="([^"]+)"/i)?.[1] ?? '';

      return {
        name: stripTags(
          rowHtml.match(/<span class="isim">([\s\S]*?)<\/span>/i)?.[1] ?? '',
        ),
        address: extractAddress(detailsHtml),
        district: extractDistrict(detailsHtml),
        phoneNumber: cleanPhone(
          stripTags(
            rowHtml.match(
              /<div class=['"]col-lg-3 py-lg-2['"]>([\s\S]*?)<\/div>/i,
            )?.[1] ?? '',
          ),
        ),
        sourceUrl: sourcePath
          ? new URL(sourcePath, SOURCE_BASE_URL).toString()
          : `${SOURCE_BASE_URL}/nobetci-${citySlug}`,
      };
    })
    .filter((record) => record.name && record.address);
}

async function scrapeCity(city) {
  const response = await axios.get(`${SOURCE_BASE_URL}/nobetci-${city.slug}`, {
    headers: DEFAULT_HEADERS,
    timeout: 60_000,
    responseType: 'text',
  });

  const tabHtml = extractTodayTabHtml(response.data);
  if (!tabHtml) {
    throw new Error('Aktif gun sekmesi parse edilemedi.');
  }

  return extractRecordsFromTab(tabHtml, city.slug);
}

// ---------------------------------------------------------------------------
// City refresh
// ---------------------------------------------------------------------------

async function refreshCity(city) {
  console.log(`\n[${city.displayName}] Starting source scrape...`);

  const records = await scrapeCity(city);
  console.log(`  Found ${records.length} pharmacies`);

  let geocoded = 0;
  let cached = 0;
  if (!skipGeocode) {
    for (const record of records) {
      const cacheKey = record.address.toLocaleLowerCase('tr').trim();
      const wasCached = !!geocodeCache[cacheKey];

      const coords = await geocode(
        record.address,
        record.district,
        city.displayName,
      );

      if (coords) {
        record.latitude = coords.latitude;
        record.longitude = coords.longitude;
        if (wasCached) cached++;
        else geocoded++;
      }
    }

    console.log(
      `  Geocoded: ${geocoded} new, ${cached} from cache, ${records.length - geocoded - cached} failed`,
    );
  } else {
    console.log('  Geocoding skipped by SKIP_GEOCODE=1');
  }

  // Build output
  const now = new Date().toISOString();
  const withCoords = records.filter((r) => r.latitude != null).length;

  const output = {
    city: city.slug,
    cityDisplayName: city.displayName,
    updatedAt: now,
    isStale: false,
    pharmacies: records.map((r) => ({
      id: generateId(r.name, r.district, city.slug),
      name: r.name,
      address: r.address,
      phoneNumber: r.phoneNumber || 'Telefon bilgisi yok',
      district: r.district || '',
      latitude: r.latitude ?? null,
      longitude: r.longitude ?? null,
      dutyStart: null,
      dutyEnd: null,
      lastVerifiedAt: now,
      source: 'Eczaneler.gen.tr',
      sourceUrl: r.sourceUrl,
    })),
  };

  console.log(
    `  Coordinates: ${withCoords}/${records.length} (${records.length === 0 ? 0 : Math.round((withCoords / records.length) * 100)}%)`,
  );

  return output;
}

// ---------------------------------------------------------------------------
// Retry wrapper
// ---------------------------------------------------------------------------

async function refreshCityWithRetry(city) {
  for (let attempt = 1; attempt <= CITY_RETRY_ATTEMPTS; attempt++) {
    try {
      return await refreshCity(city);
    } catch (error) {
      if (attempt < CITY_RETRY_ATTEMPTS) {
        console.warn(
          `  [${city.displayName}] Attempt ${attempt} failed: ${error.message}. Retrying in ${CITY_RETRY_DELAY_MS / 1000}s...`,
        );
        await sleep(CITY_RETRY_DELAY_MS);
      } else {
        throw error;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Concurrency pool
// ---------------------------------------------------------------------------

async function runWithConcurrency(tasks, concurrency) {
  const results = [];
  let index = 0;

  async function worker() {
    while (index < tasks.length) {
      const i = index++;
      if (i > 0) await sleep(INTER_CITY_DELAY_MS);
      results[i] = await tasks[i]();
    }
  }

  const workers = Array.from({ length: Math.min(concurrency, tasks.length) }, () => worker());
  await Promise.all(workers);
  return results;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const citiesToRefresh = selectedCitySlugs.length
    ? CITIES.filter((city) => selectedCitySlugs.includes(city.slug))
    : CITIES;

  console.log('=== Nobetci Pharmacy Refresh ===');
  console.log(`Date: ${new Date().toISOString()}`);
  console.log(`Cities: ${citiesToRefresh.length}, Concurrency: ${CONCURRENCY}\n`);

  mkdirSync(OUTPUT_DIR, { recursive: true });
  loadCache();

  const citiesJson = CITIES.map((c) => ({
    slug: c.slug,
    name: c.displayName,
  }));

  writeFileSync(
    resolve(OUTPUT_DIR, 'cities.json'),
    JSON.stringify(citiesJson, null, 2) + '\n',
  );

  const healthItems = new Array(citiesToRefresh.length);

  const tasks = citiesToRefresh.map((city, i) => async () => {
    try {
      const output = await refreshCityWithRetry(city);
      writeFileSync(
        resolve(OUTPUT_DIR, `${city.slug}.json`),
        JSON.stringify(output, null, 2) + '\n',
      );

      const withCoords = output.pharmacies.filter(
        (p) => p.latitude != null,
      ).length;

      healthItems[i] = {
        city: city.slug,
        cityDisplayName: city.displayName,
        lastRefreshedAt: output.updatedAt,
        pharmacyCount: output.pharmacies.length,
        withCoordinates: withCoords,
        coordCoveragePct:
          output.pharmacies.length === 0
            ? 0
            : Math.round((withCoords / output.pharmacies.length) * 100),
      };
    } catch (error) {
      console.error(`  [${city.displayName}] FAILED: ${error.message}`);
      healthItems[i] = {
        city: city.slug,
        cityDisplayName: city.displayName,
        lastRefreshedAt: null,
        pharmacyCount: 0,
        withCoordinates: 0,
        coordCoveragePct: 0,
        error: error.message,
      };
    }
  });

  await runWithConcurrency(tasks, CONCURRENCY);

  // Persist geocode cache after all cities (not per-city, to avoid race conditions)
  saveCache();

  const succeeded = healthItems.filter((h) => !h.error).length;
  const failed = healthItems.filter((h) => h.error).length;

  // Write health
  writeFileSync(
    resolve(OUTPUT_DIR, 'health.json'),
    JSON.stringify(
      { ok: failed === 0, checkedAt: new Date().toISOString(), cities: healthItems },
      null,
      2,
    ) + '\n',
  );

  console.log(`\n=== Done ===`);
  console.log(`Succeeded: ${succeeded}, Failed: ${failed}`);
  console.log(`Output: ${OUTPUT_DIR}`);

  if (failed > 0) {
    console.warn(`\nFailed cities: ${healthItems.filter((h) => h.error).map((h) => h.cityDisplayName).join(', ')}`);
  }
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
