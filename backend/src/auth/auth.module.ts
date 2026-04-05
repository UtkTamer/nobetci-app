import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AdminRefreshGuard } from './admin-refresh.guard';

@Module({
  imports: [ConfigModule],
  providers: [AdminRefreshGuard],
  exports: [AdminRefreshGuard],
})
export class AuthModule {}
