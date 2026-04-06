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

  // 06:00 UTC = 09:00 Türkiye (sabah)
  @Cron(CronExpression.EVERY_DAY_AT_6AM)
  async morningRefresh(): Promise<void> {
    this.logger.log('Morning refresh starting');
    await this.collectorsService.refreshAllCities();
  }

  // 09:00 UTC = 12:00 Türkiye (öğlen)
  @Cron('0 9 * * *')
  async noonRefresh(): Promise<void> {
    this.logger.log('Noon refresh starting');
    await this.collectorsService.refreshAllCities();
  }

  // 15:00 UTC = 18:00 Türkiye (akşam)
  @Cron('0 15 * * *')
  async eveningRefresh(): Promise<void> {
    this.logger.log('Evening refresh starting');
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
