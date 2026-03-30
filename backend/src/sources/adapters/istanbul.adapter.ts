import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';

import { GenericDutySourceAdapter } from '../generic-duty-source.adapter';

@Injectable()
export class IstanbulDutySourceAdapter extends GenericDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: 'istanbul',
      cityDisplayName: 'İstanbul',
      sourceName: 'İstanbul Eczacı Odası',
      sourceUrl: 'https://www.istanbuleczaciodasi.org.tr/nobetci-eczaneler',
    });
  }
}
