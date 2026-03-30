import { Module } from '@nestjs/common';

import { GeocodingModule } from '../geocoding/geocoding.module';
import { NormalizersModule } from '../normalizers/normalizers.module';
import { SourcesModule } from '../sources/sources.module';
import { StorageModule } from '../storage/storage.module';
import { CollectorsService } from './collectors.service';

@Module({
  imports: [SourcesModule, NormalizersModule, GeocodingModule, StorageModule],
  providers: [CollectorsService],
  exports: [CollectorsService],
})
export class CollectorsModule {}
