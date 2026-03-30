import { Module } from '@nestjs/common';

import { CollectorsModule } from '../collectors/collectors.module';
import { SourcesModule } from '../sources/sources.module';
import { StorageModule } from '../storage/storage.module';
import { ApiController } from './api.controller';
import { ApiService } from './api.service';

@Module({
  imports: [StorageModule, SourcesModule, CollectorsModule],
  controllers: [ApiController],
  providers: [ApiService],
})
export class ApiModule {}
