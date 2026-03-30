import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';

import { GenericDutySourceAdapter } from '../generic-duty-source.adapter';

@Injectable()
export class IzmirDutySourceAdapter extends GenericDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: 'izmir',
      cityDisplayName: 'İzmir',
      sourceName: 'İzmir Eczacı Odası',
      sourceUrl: 'https://www.izmireczaciodasi.org.tr/nobetci-eczaneler',
    });
  }
}
