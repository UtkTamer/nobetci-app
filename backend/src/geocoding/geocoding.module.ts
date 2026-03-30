import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

import { StorageModule } from '../storage/storage.module';
import { GeocodingService } from './geocoding.service';

@Module({
  imports: [HttpModule, StorageModule],
  providers: [GeocodingService],
  exports: [GeocodingService],
})
export class GeocodingModule {}
