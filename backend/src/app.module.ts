import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ApiModule } from './api/api.module';
import { CollectorsModule } from './collectors/collectors.module';
import { GeocodingModule } from './geocoding/geocoding.module';
import { SchedulerFeatureModule } from './scheduler/scheduler.module';
import { SourcesModule } from './sources/sources.module';
import { CityEntity } from './storage/entities/city.entity';
import { DistrictEntity } from './storage/entities/district.entity';
import { DutyRecordEntity } from './storage/entities/duty-record.entity';
import { GeocodeCacheEntity } from './storage/entities/geocode-cache.entity';
import { PharmacyEntity } from './storage/entities/pharmacy.entity';
import { SourceFetchRunEntity } from './storage/entities/source-fetch-run.entity';
import { StorageModule } from './storage/storage.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ScheduleModule.forRoot(),
    TypeOrmModule.forRootAsync({
      useFactory: () => {
        const entities = [
          CityEntity,
          DistrictEntity,
          PharmacyEntity,
          DutyRecordEntity,
          SourceFetchRunEntity,
          GeocodeCacheEntity,
        ];

        if (process.env.DB_TYPE == 'postgres') {
          return {
            type: 'postgres' as const,
            url: process.env.DATABASE_URL,
            entities,
            synchronize: true,
          };
        }

        return {
          type: 'sqljs' as const,
          autoSave: true,
          location: '.data/nobetci.sqlite',
          entities,
          synchronize: true,
        };
      },
    }),
    StorageModule,
    GeocodingModule,
    SourcesModule,
    CollectorsModule,
    SchedulerFeatureModule,
    ApiModule,
  ],
})
export class AppModule {}
