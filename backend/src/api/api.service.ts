import { Injectable } from '@nestjs/common';

import { CollectorsService } from '../collectors/collectors.service';
import { SourcesService } from '../sources/sources.service';
import { StorageService } from '../storage/storage.service';

const staleThresholdMs = 18 * 60 * 60 * 1000;

@Injectable()
export class ApiService {
  constructor(
    private readonly storageService: StorageService,
    private readonly sourcesService: SourcesService,
    private readonly collectorsService: CollectorsService,
  ) {}

  async listCities() {
    const storedCities = await this.storageService.listCities();
    const cityMap = new Map<string, string>();

    for (const source of this.sourcesService.getAll()) {
      cityMap.set(source.citySlug, source.cityDisplayName);
    }

    for (const city of storedCities) {
      cityMap.set(city.slug, this._toDisplayName(city.name));
    }

    return [...cityMap.entries()]
      .map(([slug, name]) => ({ slug, name }))
      .sort((left, right) => left.name.localeCompare(right.name, 'tr'));
  }

  async listDistricts(citySlug: string) {
    const districts = await this.storageService.listDistricts(citySlug);
    return districts.map((district) => ({
      slug: district.slug,
      name: district.name,
      citySlug,
    }));
  }

  async getOnDuty(citySlug: string, districtSlug?: string) {
    const [records, lastFetch] = await Promise.all([
      this.storageService.getOnDutyPharmacies(citySlug, districtSlug),
      this.storageService.getLastSuccessfulFetch(citySlug),
    ]);

    const source = this.sourcesService.getBySlug(citySlug);
    if (source != null) {
      this.collectorsService.triggerBackgroundRefreshIfNeeded(
        citySlug,
        staleThresholdMs,
      );
    }

    const updatedAt = lastFetch?.finishedAt ?? new Date();
    const isStale = Date.now() - updatedAt.getTime() > staleThresholdMs;
    const cityDisplayName =
      records[0]?.cityDisplayName ??
      source?.cityDisplayName ??
      this._toDisplayName(citySlug);

    return {
      city: citySlug,
      cityDisplayName,
      updatedAt: updatedAt.toISOString(),
      isStale,
      pharmacies: records.map((record) => ({
        id: record.pharmacy.id,
        name: record.pharmacy.name,
        address: record.pharmacy.address,
        phoneNumber: record.pharmacy.phoneNumber,
        district: record.district.name,
        latitude: record.pharmacy.latitude,
        longitude: record.pharmacy.longitude,
        dutyStart: record.dutyStart?.toISOString() ?? null,
        dutyEnd: record.dutyEnd?.toISOString() ?? null,
        lastVerifiedAt: record.lastVerifiedAt.toISOString(),
        source: record.source,
        sourceUrl: record.sourceUrl,
      })),
    };
  }

  async getNearby(citySlug: string, lat: number, lng: number, districtSlug?: string) {
    const payload = await this.getOnDuty(citySlug, districtSlug);
    const withDistance = payload.pharmacies
      .map((pharmacy) => ({
        ...pharmacy,
        distanceKm:
          pharmacy.latitude == null || pharmacy.longitude == null
              ? null
              : this.distanceKm(lat, lng, pharmacy.latitude, pharmacy.longitude),
      }))
      .sort((left, right) => {
        if (left.distanceKm == null) {
          return 1;
        }

        if (right.distanceKm == null) {
          return -1;
        }

        return left.distanceKm - right.distanceKm;
      });

    return {
      ...payload,
      pharmacies: withDistance,
    };
  }

  async getHealth() {
    const sources = this.sourcesService.getAll();
    const cityHealthItems = await Promise.all(
      sources.map(async (source) => {
        const [lastFetch, records] = await Promise.all([
          this.storageService.getLastSuccessfulFetch(source.citySlug),
          this.storageService.getOnDutyPharmacies(source.citySlug),
        ]);

        const total = records.length;
        const withCoords = records.filter(
          (r) => r.pharmacy.latitude != null && r.pharmacy.longitude != null,
        ).length;
        const coordCoveragePct =
          total === 0 ? 0 : Math.round((withCoords / total) * 100);

        return {
          city: source.citySlug,
          cityDisplayName: source.cityDisplayName,
          lastRefreshedAt: lastFetch?.finishedAt?.toISOString() ?? null,
          pharmacyCount: total,
          withCoordinates: withCoords,
          coordCoveragePct,
          isStale: lastFetch == null ||
            Date.now() - lastFetch.finishedAt.getTime() > staleThresholdMs,
        };
      }),
    );

    return {
      ok: true,
      checkedAt: new Date().toISOString(),
      cities: cityHealthItems,
    };
  }

  private distanceKm(lat1: number, lon1: number, lat2: number, lon2: number) {
    const toRadians = (value: number) => (value * Math.PI) / 180;
    const earthRadiusKm = 6371;
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRadians(lat1)) *
        Math.cos(toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  private _toDisplayName(value: string) {
    if (value.length === 0) {
      return value;
    }

    return value[0].toUpperCase() + value.slice(1).toLowerCase();
  }
}
