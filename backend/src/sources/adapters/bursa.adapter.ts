import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';

import { GenericDutySourceAdapter } from '../generic-duty-source.adapter';

@Injectable()
export class BursaDutySourceAdapter extends GenericDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: 'bursa',
      cityDisplayName: 'Bursa',
      sourceName: 'Bursa Eczacı Odası',
      sourceUrl: 'https://www.beo.org.tr/nobetci-eczaneler',
    });
  }
}
