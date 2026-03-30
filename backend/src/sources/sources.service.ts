import { Injectable } from '@nestjs/common';

import { DutySourceAdapter } from '../common/types';
import { AnkaraDutySourceAdapter } from './adapters/ankara.adapter';
import { AntalyaDutySourceAdapter } from './adapters/antalya.adapter';
import { BursaDutySourceAdapter } from './adapters/bursa.adapter';
import { IstanbulDutySourceAdapter } from './adapters/istanbul.adapter';
import { IzmirDutySourceAdapter } from './adapters/izmir.adapter';

@Injectable()
export class SourcesService {
  constructor(
    private readonly istanbulAdapter: IstanbulDutySourceAdapter,
    private readonly ankaraAdapter: AnkaraDutySourceAdapter,
    private readonly izmirAdapter: IzmirDutySourceAdapter,
    private readonly bursaAdapter: BursaDutySourceAdapter,
    private readonly antalyaAdapter: AntalyaDutySourceAdapter,
  ) {}

  getAll(): DutySourceAdapter[] {
    return [
      this.istanbulAdapter,
      this.ankaraAdapter,
      this.izmirAdapter,
      this.bursaAdapter,
      this.antalyaAdapter,
    ];
  }

  getBySlug(citySlug: string): DutySourceAdapter | undefined {
    return this.getAll().find((source) => source.citySlug === citySlug);
  }
}
