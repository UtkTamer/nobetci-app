export type CitySlug = 'istanbul' | 'ankara' | 'izmir' | 'bursa' | 'antalya';

export interface RawPharmacyRecord {
  name: string;
  address: string;
  phoneNumber?: string;
  district?: string;
  latitude?: number | null;
  longitude?: number | null;
  dutyStart?: Date | null;
  dutyEnd?: Date | null;
  sourceUrl: string;
}

export interface NormalizedPharmacyRecord {
  name: string;
  normalizedName: string;
  address: string;
  normalizedAddress: string;
  phoneNumber: string;
  districtName: string;
  citySlug: CitySlug;
  cityDisplayName: string;
  latitude: number | null;
  longitude: number | null;
  dutyStart: Date | null;
  dutyEnd: Date | null;
  source: string;
  sourceUrl: string;
  lastVerifiedAt: Date;
}

export interface ParsedCityResult {
  citySlug: CitySlug;
  cityDisplayName: string;
  source: string;
  records: RawPharmacyRecord[];
  fetchedAt: Date;
}

export interface DutySourceAdapter {
  readonly citySlug: CitySlug;
  readonly cityDisplayName: string;
  readonly sourceName: string;
  readonly sourceUrl: string;

  fetchAndParse(): Promise<ParsedCityResult>;
}
