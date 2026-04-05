import {
  Controller,
  Get,
  ParseFloatPipe,
  Query,
  UseGuards,
} from '@nestjs/common';

import { AdminRefreshGuard } from '../auth/admin-refresh.guard';
import { CollectorsService } from '../collectors/collectors.service';
import { ApiService } from './api.service';

@Controller()
export class ApiController {
  constructor(
    private readonly apiService: ApiService,
    private readonly collectorsService: CollectorsService,
  ) {}

  @Get('cities')
  async listCities() {
    return this.apiService.listCities();
  }

  @Get('districts')
  async listDistricts(@Query('city') city: string) {
    return this.apiService.listDistricts(city);
  }

  @Get('pharmacies/on-duty')
  async getOnDuty(
    @Query('city') city: string,
    @Query('district') district?: string,
  ) {
    return this.apiService.getOnDuty(city, district);
  }

  @Get('pharmacies/nearby')
  async getNearby(
    @Query('city') city: string,
    @Query('lat', ParseFloatPipe) lat: number,
    @Query('lng', ParseFloatPipe) lng: number,
    @Query('district') district?: string,
  ) {
    return this.apiService.getNearby(city, lat, lng, district);
  }

  @Get('admin/refresh')
  @UseGuards(AdminRefreshGuard)
  async refresh(@Query('city') city?: string) {
    if (city != null && city.length > 0) {
      await this.collectorsService.refreshCity(city);
      return { ok: true, city };
    }

    await this.collectorsService.refreshAllCities();
    return { ok: true, city: 'all' };
  }
}
