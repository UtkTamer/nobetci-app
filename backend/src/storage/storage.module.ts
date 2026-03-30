import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CityEntity } from './entities/city.entity';
import { DistrictEntity } from './entities/district.entity';
import { DutyRecordEntity } from './entities/duty-record.entity';
import { GeocodeCacheEntity } from './entities/geocode-cache.entity';
import { PharmacyEntity } from './entities/pharmacy.entity';
import { SourceFetchRunEntity } from './entities/source-fetch-run.entity';
import { StorageService } from './storage.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      CityEntity,
      DistrictEntity,
      PharmacyEntity,
      DutyRecordEntity,
      SourceFetchRunEntity,
      GeocodeCacheEntity,
    ]),
  ],
  providers: [StorageService],
  exports: [StorageService],
})
export class StorageModule {}
