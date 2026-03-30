import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';
import { firstValueFrom } from 'rxjs';

import { StorageService } from '../storage/storage.service';

@Injectable()
export class GeocodingService {
  constructor(
    private readonly httpService: HttpService,
    private readonly storageService: StorageService,
  ) {}

  async resolve(
    rawAddress: string,
  ): Promise<{ latitude: number; longitude: number } | null> {
    const addressKey = rawAddress.toLocaleLowerCase('tr').trim();
    const cached = await this.storageService.findGeocode(addressKey);
    if (cached != null) {
      return {
        latitude: cached.latitude,
        longitude: cached.longitude,
      };
    }

    const response = await firstValueFrom(
      this.httpService.get<Array<{ lat: string; lon: string }>>(
        'https://nominatim.openstreetmap.org/search',
        {
          params: {
            q: rawAddress,
            format: 'jsonv2',
            limit: 1,
          },
          headers: {
            'User-Agent':
              process.env.GEOCODING_USER_AGENT ?? 'nobetci-app/1.0',
          },
        },
      ),
    );

    const result = response.data[0];
    if (result == null) {
      return null;
    }

    const latitude = Number(result.lat);
    const longitude = Number(result.lon);
    await this.storageService.saveGeocode(
      addressKey,
      rawAddress,
      latitude,
      longitude,
    );

    return { latitude, longitude };
  }
}
