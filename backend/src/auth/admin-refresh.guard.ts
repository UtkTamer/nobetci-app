import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AdminRefreshGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context
      .switchToHttp()
      .getRequest<{ headers: Record<string, string | string[] | undefined> }>();
    const refreshTokenHeader = request.headers['x-admin-refresh-token'];
    const headerValue = Array.isArray(refreshTokenHeader)
      ? refreshTokenHeader[0]
      : refreshTokenHeader;

    const adminRefreshToken =
      this.configService.get<string>('ADMIN_REFRESH_TOKEN') ?? '';

    if (
      headerValue == null ||
      headerValue.length === 0 ||
      adminRefreshToken.length === 0 ||
      headerValue != adminRefreshToken
    ) {
      throw new UnauthorizedException('Invalid admin refresh token.');
    }

    return true;
  }
}
