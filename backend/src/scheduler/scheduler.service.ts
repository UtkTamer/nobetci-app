import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { CollectorsService } from '../collectors/collectors.service';

@Injectable()
export class SchedulerService {
  constructor(private readonly collectorsService: CollectorsService) {}

  @Cron(CronExpression.EVERY_DAY_AT_6AM)
  async morningRefresh(): Promise<void> {
    await this.collectorsService.refreshAllCities();
  }

  @Cron(CronExpression.EVERY_DAY_AT_NOON)
  async noonRefresh(): Promise<void> {
    await this.collectorsService.refreshAllCities();
  }

  @Cron(CronExpression.EVERY_DAY_AT_6PM)
  async eveningRefresh(): Promise<void> {
    await this.collectorsService.refreshAllCities();
  }
}
