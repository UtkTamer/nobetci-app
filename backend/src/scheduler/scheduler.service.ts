import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';

import { CollectorsService } from '../collectors/collectors.service';

@Injectable()
export class SchedulerService implements OnModuleInit {
  private readonly logger = new Logger(SchedulerService.name);

  constructor(private readonly collectorsService: CollectorsService) {}

  onModuleInit(): void {
    void this.preloadCities();
  }

  @Cron(CronExpression.EVERY_DAY_AT_6AM)
  async morningRefresh(): Promise<void> {
    await this.collectorsService.refreshAllCities();
  }

  @Cron(CronExpression.EVERY_DAY_AT_6PM)
  async eveningRefresh(): Promise<void> {
    await this.collectorsService.refreshAllCities();
  }

  private async preloadCities(): Promise<void> {
    try {
      // Warm the cache at startup so city switches don't wait on a live scrape.
      await this.collectorsService.refreshAllCities();
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown preload error';
      this.logger.warn(`Initial city preload failed: ${message}`);
    }
  }
}
