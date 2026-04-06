import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { firstValueFrom } from 'rxjs';

import { StorageService } from '../storage/storage.service';

const NOMINATIM_RATE_LIMIT_MS = 1200; // Nominatim ToS: max 1 req/sec
const MAX_RETRY_ATTEMPTS = 3;

@Injectable()
export class GeocodingService {
  private readonly logger = new Logger(GeocodingService.name);
  private lastNominatimCallAt = 0;

  constructor(
    private readonly httpService: HttpService,
    private readonly storageService: StorageService,
  ) {}

  async resolve(
    rawAddress: string,
  ): Promise<{ latitude: number; longitude: number } | null> {
    const addressKey = rawAddress.toLocaleLowerCase('tr').trim();
    const cached = await this.storageService.findGeocode(addressKey);
    if (cached != null) {
      return {
        latitude: cached.latitude,
        longitude: cached.longitude,
      };
    }

    const cleanedAddress = this.cleanTurkishAddress(rawAddress);
    this.logger.debug(`Geocoding: "${rawAddress}" → "${cleanedAddress}"`);

    await this.waitForRateLimit();

    let lastError: unknown = null;
    for (let attempt = 0; attempt < MAX_RETRY_ATTEMPTS; attempt += 1) {
      if (attempt > 0) {
        const backoffMs = 2000 * attempt;
        this.logger.warn(
          `Geocoding retry ${attempt}/${MAX_RETRY_ATTEMPTS - 1} for "${rawAddress}" in ${backoffMs}ms`,
        );
        await GeocodingService.sleep(backoffMs);
        await this.waitForRateLimit();
      }

      try {
        const response = await firstValueFrom(
          this.httpService.get<Array<{ lat: string; lon: string }>>(
            'https://nominatim.openstreetmap.org/search',
            {
              params: {
                q: cleanedAddress,
                format: 'jsonv2',
                limit: 1,
              },
              headers: {
                'User-Agent':
                  process.env.GEOCODING_USER_AGENT ?? 'nobetci-app/1.0',
              },
            },
          ),
        );

        const result = response.data[0];
        if (result == null) {
          return null;
        }

        const latitude = Number(result.lat);
        const longitude = Number(result.lon);
        await this.storageService.saveGeocode(
          addressKey,
          rawAddress,
          latitude,
          longitude,
        );

        return { latitude, longitude };
      } catch (error) {
        lastError = error;
      }
    }

    const message =
      lastError instanceof Error ? lastError.message : String(lastError);
    this.logger.error(`Geocoding failed after ${MAX_RETRY_ATTEMPTS} attempts for "${rawAddress}": ${message}`);
    return null;
  }

  private async waitForRateLimit(): Promise<void> {
    const now = Date.now();
    const elapsed = now - this.lastNominatimCallAt;
    if (elapsed < NOMINATIM_RATE_LIMIT_MS) {
      await GeocodingService.sleep(NOMINATIM_RATE_LIMIT_MS - elapsed);
    }
    this.lastNominatimCallAt = Date.now();
  }

  /**
   * Cleans a raw Turkish pharmacy address for better Nominatim results.
   *
   * Example:
   *   "BAHÇELİEVLER MAH. AŞKAABAT CAD. NO:29/4"
   *   → "Bahçelievler Mahallesi Aşkaabat Caddesi"
   */
  cleanTurkishAddress(raw: string): string {
    let address = raw;

    // Remove building/apartment numbers: NO:29/4, NO: 23/E, No: 12 A
    address = address.replace(/\bNO\s*:\s*\S+/gi, '');
    // Remove standalone block/apartment references: BLK, KAT, D:, DAİRE
    address = address.replace(/\b(BLK|BLOK|KAT|D:|DAİRE)\s*\S*/gi, '');

    // Expand common Turkish abbreviations
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
    address = address.replace(/\bMEVKİİ\b/gi, 'Mevkii');
    address = address.replace(/\bSİT\.\s*/gi, 'Sitesi ');

    // Convert to title case (UPPERCASE → Title Case)
    address = address
      .toLocaleLowerCase('tr')
      .replace(/(^|\s)\S/g, (char) => char.toLocaleUpperCase('tr'));

    // Clean up extra spaces
    address = address.replace(/\s+/g, ' ').trim();

    return address;
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
