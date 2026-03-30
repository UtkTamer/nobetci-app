import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { NormalizedPharmacyRecord } from '../common/types';
import { CityEntity } from './entities/city.entity';
import { DistrictEntity } from './entities/district.entity';
import { DutyRecordEntity } from './entities/duty-record.entity';
import { GeocodeCacheEntity } from './entities/geocode-cache.entity';
import { PharmacyEntity } from './entities/pharmacy.entity';
import { SourceFetchRunEntity } from './entities/source-fetch-run.entity';

@Injectable()
export class StorageService {
  constructor(
    @InjectRepository(CityEntity)
    private readonly cityRepository: Repository<CityEntity>,
    @InjectRepository(DistrictEntity)
    private readonly districtRepository: Repository<DistrictEntity>,
    @InjectRepository(PharmacyEntity)
    private readonly pharmacyRepository: Repository<PharmacyEntity>,
    @InjectRepository(DutyRecordEntity)
    private readonly dutyRecordRepository: Repository<DutyRecordEntity>,
    @InjectRepository(SourceFetchRunEntity)
    private readonly fetchRunRepository: Repository<SourceFetchRunEntity>,
    @InjectRepository(GeocodeCacheEntity)
    private readonly geocodeCacheRepository: Repository<GeocodeCacheEntity>,
  ) {}

  async listCities(): Promise<CityEntity[]> {
    return this.cityRepository.find({ order: { name: 'ASC' } });
  }

  async listDistricts(citySlug: string): Promise<DistrictEntity[]> {
    return this.districtRepository.find({
      where: { city: { slug: citySlug } },
      order: { name: 'ASC' },
    });
  }

  async findGeocode(addressKey: string): Promise<GeocodeCacheEntity | null> {
    return this.geocodeCacheRepository.findOne({ where: { addressKey } });
  }

  async saveGeocode(
    addressKey: string,
    rawAddress: string,
    latitude: number,
    longitude: number,
  ): Promise<void> {
    const existing = await this.findGeocode(addressKey);
    if (existing != null) {
      existing.latitude = latitude;
      existing.longitude = longitude;
      existing.lastResolvedAt = new Date();
      await this.geocodeCacheRepository.save(existing);
      return;
    }

    await this.geocodeCacheRepository.save({
      addressKey,
      rawAddress,
      latitude,
      longitude,
      lastResolvedAt: new Date(),
    });
  }

  async replaceCityDutyRecords(
    citySlug: string,
    records: NormalizedPharmacyRecord[],
  ): Promise<void> {
    const cityName = records[0]?.cityDisplayName ?? citySlug;
    let city = await this.cityRepository.findOne({ where: { slug: citySlug } });

    if (city == null) {
      city = await this.cityRepository.save({ slug: citySlug, name: cityName });
    }

    const activeRecords = await this.dutyRecordRepository.find({
      where: { citySlug, isActive: true },
    });

    for (const finalRecord of activeRecords) {
      finalRecord.isActive = false;
      await this.dutyRecordRepository.save(finalRecord);
    }

    for (const record of records) {
      const district = await this.findOrCreateDistrict(city, record.districtName);
      const pharmacy = await this.findOrCreatePharmacy(record, district);

      await this.dutyRecordRepository.save({
        pharmacy,
        district,
        citySlug: record.citySlug,
        cityDisplayName: record.cityDisplayName,
        source: record.source,
        sourceUrl: record.sourceUrl,
        dutyStart: record.dutyStart,
        dutyEnd: record.dutyEnd,
        lastVerifiedAt: record.lastVerifiedAt,
        isActive: true,
      });
    }
  }

  async createFetchRun(input: {
    citySlug: string;
    source: string;
    status: 'success' | 'failed';
    recordCount: number;
    errorMessage?: string | null;
    startedAt: Date;
    finishedAt: Date;
  }): Promise<void> {
    await this.fetchRunRepository.save({
      ...input,
      errorMessage: input.errorMessage ?? null,
    });
  }

  async getOnDutyPharmacies(citySlug: string, districtSlug?: string) {
    const query = this.dutyRecordRepository
      .createQueryBuilder('duty')
      .leftJoinAndSelect('duty.pharmacy', 'pharmacy')
      .leftJoinAndSelect('duty.district', 'district')
      .leftJoinAndSelect('district.city', 'city')
      .where('duty.citySlug = :citySlug', { citySlug })
      .andWhere('duty.isActive = true');

    if (districtSlug != null && districtSlug.length > 0) {
      query.andWhere('district.slug = :districtSlug', { districtSlug });
    }

    return query.orderBy('pharmacy.name', 'ASC').getMany();
  }

  async getLastSuccessfulFetch(citySlug: string): Promise<SourceFetchRunEntity | null> {
    return this.fetchRunRepository.findOne({
      where: { citySlug, status: 'success' },
      order: { finishedAt: 'DESC' },
    });
  }

  private async findOrCreateDistrict(
    city: CityEntity,
    districtName: string,
  ): Promise<DistrictEntity> {
    const resolvedName = districtName.length === 0 ? 'Merkez' : districtName;
    const slug = this.slugify(resolvedName);
    const existing = await this.districtRepository.findOne({
      where: { city: { id: city.id }, slug },
    });

    if (existing != null) {
      return existing;
    }

    return this.districtRepository.save({
      city,
      name: resolvedName,
      slug,
    });
  }

  private async findOrCreatePharmacy(
    record: NormalizedPharmacyRecord,
    district: DistrictEntity,
  ): Promise<PharmacyEntity> {
    const existingByPhone =
        record.phoneNumber.length > 0
            ? await this.pharmacyRepository.findOne({
                where: {
                  normalizedName: record.normalizedName,
                  phoneNumber: record.phoneNumber,
                  district: { id: district.id },
                },
              })
            : null;

    const existingByAddress =
      existingByPhone ??
      (await this.pharmacyRepository.findOne({
        where: {
          normalizedName: record.normalizedName,
          normalizedAddress: record.normalizedAddress,
          district: { id: district.id },
        },
      }));

    if (existingByAddress != null) {
      existingByAddress.latitude = record.latitude;
      existingByAddress.longitude = record.longitude;
      existingByAddress.address = record.address;
      existingByAddress.phoneNumber = record.phoneNumber;
      return this.pharmacyRepository.save(existingByAddress);
    }

    return this.pharmacyRepository.save({
      name: record.name,
      normalizedName: record.normalizedName,
      address: record.address,
      normalizedAddress: record.normalizedAddress,
      phoneNumber: record.phoneNumber,
      latitude: record.latitude,
      longitude: record.longitude,
      district,
    });
  }

  private slugify(value: string): string {
    return value
      .toLocaleLowerCase('tr')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .replaceAll(/[^a-z0-9]+/g, '-')
      .replaceAll(/^-+|-+$/g, '');
  }
}
