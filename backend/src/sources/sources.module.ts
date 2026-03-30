import { HttpModule } from '@nestjs/axios';
import { Module } from '@nestjs/common';

import { AnkaraDutySourceAdapter } from './adapters/ankara.adapter';
import { AntalyaDutySourceAdapter } from './adapters/antalya.adapter';
import { BursaDutySourceAdapter } from './adapters/bursa.adapter';
import { IstanbulDutySourceAdapter } from './adapters/istanbul.adapter';
import { IzmirDutySourceAdapter } from './adapters/izmir.adapter';
import { SourcesService } from './sources.service';

@Module({
  imports: [HttpModule],
  providers: [
    IstanbulDutySourceAdapter,
    AnkaraDutySourceAdapter,
    IzmirDutySourceAdapter,
    BursaDutySourceAdapter,
    AntalyaDutySourceAdapter,
    SourcesService,
  ],
  exports: [SourcesService],
})
export class SourcesModule {}
