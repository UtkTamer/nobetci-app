import { Injectable, Logger } from '@nestjs/common';

import { GeocodingService } from '../geocoding/geocoding.service';
import { PharmacyNormalizerService } from '../normalizers/pharmacy-normalizer.service';
import { SourcesService } from '../sources/sources.service';
import { StorageService } from '../storage/storage.service';

@Injectable()
export class CollectorsService {
  private readonly logger = new Logger(CollectorsService.name);
  private readonly inFlightRefreshes = new Map<string, Promise<void>>();

  constructor(
    private readonly sourcesService: SourcesService,
    private readonly normalizerService: PharmacyNormalizerService,
    private readonly geocodingService: GeocodingService,
    private readonly storageService: StorageService,
  ) {}

  async refreshAllCities(): Promise<void> {
    const adapters = this.sourcesService.getAll();
    for (const adapter of adapters) {
      try {
        await this.refreshCity(adapter.citySlug);
      } catch (error) {
        const message =
          error instanceof Error ? error.message : 'Unknown collection error';
        this.logger.warn(
          `City refresh skipped for ${adapter.citySlug}: ${message}`,
        );
      }
    }
  }

  async refreshCity(citySlug: string): Promise<void> {
    const inFlightRefresh = this.inFlightRefreshes.get(citySlug);
    if (inFlightRefresh != null) {
      await inFlightRefresh;
      return;
    }

    const refreshPromise = this.performRefreshCity(citySlug).finally(() => {
      this.inFlightRefreshes.delete(citySlug);
    });
    this.inFlightRefreshes.set(citySlug, refreshPromise);

    await refreshPromise;
  }

  async refreshCityIfNeeded(citySlug: string, maxAgeMs: number): Promise<boolean> {
    const lastFetch = await this.storageService.getLastSuccessfulFetch(citySlug);
    if (
      lastFetch != null &&
      Date.now() - lastFetch.finishedAt.getTime() <= maxAgeMs
    ) {
      return false;
    }

    await this.refreshCity(citySlug);
    return true;
  }

  triggerBackgroundRefreshIfNeeded(citySlug: string, maxAgeMs: number): void {
    void this.refreshCityIfNeeded(citySlug, maxAgeMs).catch((error) => {
      const message =
        error instanceof Error ? error.message : 'Unknown collection error';
      this.logger.warn(`Background refresh failed for ${citySlug}: ${message}`);
    });
  }

  private async performRefreshCity(citySlug: string): Promise<void> {
    const adapter = this.sourcesService
      .getAll()
      .find((item) => item.citySlug === citySlug);

    if (adapter == null) {
      throw new Error(`Unknown city adapter: ${citySlug}`);
    }

    const startedAt = new Date();

    try {
      const parsed = await adapter.fetchAndParse();
      const normalized = this.normalizerService.normalize(parsed);

      for (const record of normalized) {
        if (record.latitude == null || record.longitude == null) {
          try {
            const districtPart =
              record.districtName.length > 0
                ? `${record.districtName}, `
                : '';
            const geocode = await this.geocodingService.resolve(
              `${record.address}, ${districtPart}${record.cityDisplayName}, Türkiye`,
            );

            if (geocode != null) {
              record.latitude = geocode.latitude;
              record.longitude = geocode.longitude;
            }
          } catch (error) {
            const message =
              error instanceof Error ? error.message : 'Unknown geocoding error';
            this.logger.warn(
              `Geocoding skipped for ${record.name} in ${citySlug}: ${message}`,
            );
          }
        }
      }

      await this.storageService.replaceCityDutyRecords(citySlug, normalized);
      await this.storageService.createFetchRun({
        citySlug,
        source: adapter.sourceName,
        status: 'success',
        recordCount: normalized.length,
        startedAt,
        finishedAt: new Date(),
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown collection error';
      this.logger.error(`Refresh failed for ${citySlug}: ${message}`);
      await this.storageService.createFetchRun({
        citySlug,
        source: adapter.sourceName,
        status: 'failed',
        recordCount: 0,
        errorMessage: message,
        startedAt,
        finishedAt: new Date(),
      });
      throw error;
    }
  }
}
