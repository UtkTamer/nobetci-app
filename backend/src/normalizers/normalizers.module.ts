import { Module } from '@nestjs/common';

import { PharmacyNormalizerService } from './pharmacy-normalizer.service';

@Module({
  providers: [PharmacyNormalizerService],
  exports: [PharmacyNormalizerService],
})
export class NormalizersModule {}
