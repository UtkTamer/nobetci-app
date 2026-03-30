import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';
import * as cheerio from 'cheerio';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { firstValueFrom } from 'rxjs';

import {
  ParsedCityResult,
  RawPharmacyRecord,
} from '../../common/types';

@Injectable()
export class AnkaraDutySourceAdapter {
  private readonly execFileAsync = promisify(execFile);

  constructor(private readonly httpService: HttpService) {}

  readonly citySlug = 'ankara' as const;
  readonly cityDisplayName = 'Ankara';
  readonly sourceName = 'Eczaneler.gen.tr';
  readonly sourceUrl = 'https://www.eczaneler.gen.tr/iframe.php?lokasyon=06';

  async fetchAndParse(): Promise<ParsedCityResult> {
    const html = await this.fetchHtml();

    return {
      citySlug: this.citySlug,
      cityDisplayName: this.cityDisplayName,
      source: this.sourceName,
      fetchedAt: new Date(),
      records: this.parseHtml(html),
    };
  }

  parseHtml(html: string): RawPharmacyRecord[] {
    const $ = cheerio.load(html);
    const rows = $('tr').toArray();
    const records: RawPharmacyRecord[] = [];

    for (let index = 0; index < rows.length; index += 1) {
      const nameRow = $(rows[index]);
      const nameIconAlt = nameRow.find('img').first().attr('alt');

      if (nameIconAlt !== 'eczane') {
        continue;
      }

      const phoneRow = $(rows[index + 1]);
      const addressRow = $(rows[index + 2]);
      const nameCell = nameRow.find('td').eq(1);
      const phoneCell = phoneRow.find('td').eq(1);
      const addressCell = addressRow.find('td').eq(1);

      const name = nameCell.find('b').first().text().trim();
      const district = this.extractDistrict(nameCell.text());
      const phoneNumber = phoneCell.text().trim();
      const address = this.extractAddress(addressCell);
      const coordinates = this.extractCoordinates(nameCell);

      if (name.length === 0 || address.length === 0) {
        continue;
      }

      records.push({
        name,
        address,
        phoneNumber,
        district,
        latitude: coordinates?.latitude ?? null,
        longitude: coordinates?.longitude ?? null,
        sourceUrl: this.sourceUrl,
      });
    }

    return records;
  }

  private async fetchHtml(): Promise<string> {
    try {
      const response = await firstValueFrom(
        this.httpService.get<string>(this.sourceUrl, {
          responseType: 'text' as never,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
            Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
        }),
      );

      return response.data;
    } catch (_) {
      const { stdout } = await this.execFileAsync('curl', ['-Ls', this.sourceUrl]);
      return stdout;
    }
  }

  private extractDistrict(text: string): string {
    const match = text.match(/\(([^)]+)\)\s*$/);
    return match?.[1]?.trim() ?? '';
  }

  private extractAddress(cell: cheerio.Cheerio<any>): string {
    const clonedCell = cell.clone();
    clonedCell.find('span.text-muted').remove();
    return clonedCell.text().replace(/\s+/g, ' ').trim();
  }

  private extractCoordinates(cell: cheerio.Cheerio<any>) {
    const href = cell.find('a[href*="google.com/maps?daddr="]').attr('href');
    if (href == null) {
      return null;
    }

    const match = href.match(/daddr=([-0-9.]+),([-0-9.]+)/);
    if (match == null) {
      return null;
    }

    return {
      latitude: Number(match[1]),
      longitude: Number(match[2]),
    };
  }
}
