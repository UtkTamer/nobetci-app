import { Module } from '@nestjs/common';

import { CollectorsModule } from '../collectors/collectors.module';
import { SchedulerService } from './scheduler.service';

@Module({
  imports: [CollectorsModule],
  providers: [SchedulerService],
})
export class SchedulerFeatureModule {}
