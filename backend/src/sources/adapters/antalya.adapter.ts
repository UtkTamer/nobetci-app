import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';

import { GenericDutySourceAdapter } from '../generic-duty-source.adapter';

@Injectable()
export class AntalyaDutySourceAdapter extends GenericDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: 'antalya',
      cityDisplayName: 'Antalya',
      sourceName: 'Antalya Eczacı Odası',
      sourceUrl: 'https://www.antalyaeo.org.tr/tr/nobetci-eczaneler/',
    });
  }
}
