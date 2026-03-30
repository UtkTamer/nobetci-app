import { Injectable } from '@nestjs/common';

import {
  NormalizedPharmacyRecord,
  ParsedCityResult,
  RawPharmacyRecord,
} from '../common/types';

@Injectable()
export class PharmacyNormalizerService {
  normalize(result: ParsedCityResult): NormalizedPharmacyRecord[] {
    return result.records.map((record) => this.normalizeRecord(result, record));
  }

  private normalizeRecord(
    result: ParsedCityResult,
    record: RawPharmacyRecord,
  ): NormalizedPharmacyRecord {
    return {
      name: record.name.trim(),
      normalizedName: this.normalizeText(record.name),
      address: record.address.trim(),
      normalizedAddress: this.normalizeText(record.address),
      phoneNumber: (record.phoneNumber ?? '').trim(),
      districtName: (record.district ?? '').trim(),
      citySlug: result.citySlug,
      cityDisplayName: result.cityDisplayName,
      latitude: record.latitude ?? null,
      longitude: record.longitude ?? null,
      dutyStart: record.dutyStart ?? null,
      dutyEnd: record.dutyEnd ?? null,
      source: result.source,
      sourceUrl: record.sourceUrl,
      lastVerifiedAt: result.fetchedAt,
    };
  }

  private normalizeText(value: string): string {
    return value
      .toLocaleLowerCase('tr')
      .replaceAll(/[^a-z0-9çğıöşü]+/gu, ' ')
      .trim()
      .replaceAll(/\s+/g, ' ');
  }
}
