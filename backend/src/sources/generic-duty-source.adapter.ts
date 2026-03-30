import { HttpService } from '@nestjs/axios';
import { Injectable } from '@nestjs/common';
import * as cheerio from 'cheerio';
import { firstValueFrom } from 'rxjs';

import {
  CitySlug,
  DutySourceAdapter,
  ParsedCityResult,
  RawPharmacyRecord,
} from '../common/types';

interface GenericAdapterConfig {
  citySlug: CitySlug;
  cityDisplayName: string;
  sourceName: string;
  sourceUrl: string;
}

@Injectable()
export class GenericDutySourceAdapter implements DutySourceAdapter {
  constructor(
    private readonly httpService: HttpService,
    private readonly config: GenericAdapterConfig,
  ) {}

  get citySlug() {
    return this.config.citySlug;
  }

  get cityDisplayName() {
    return this.config.cityDisplayName;
  }

  get sourceName() {
    return this.config.sourceName;
  }

  get sourceUrl() {
    return this.config.sourceUrl;
  }

  async fetchAndParse(): Promise<ParsedCityResult> {
    const response = await firstValueFrom(
      this.httpService.get<string>(this.sourceUrl, {
        responseType: 'text' as never,
      }),
    );

    return {
      citySlug: this.citySlug,
      cityDisplayName: this.cityDisplayName,
      source: this.sourceName,
      fetchedAt: new Date(),
      records: this.parseHtml(response.data),
    };
  }

  parseHtml(html: string): RawPharmacyRecord[] {
    const $ = cheerio.load(html);
    const lineText = $('body')
      .find('*')
      .toArray()
      .map((element) => $(element).text().trim())
      .filter((line) => line.length > 0);

    const records: RawPharmacyRecord[] = [];
    let district = '';
    let currentName = '';
    let currentPhone = '';

    for (const line of lineText) {
      if (this.looksLikeDistrict(line)) {
        district = line;
        continue;
      }

      if (this.looksLikePhone(line)) {
        currentPhone = line;
        continue;
      }

      if (this.looksLikePharmacyName(line)) {
        currentName = line;
        continue;
      }

      if (currentName.length > 0 && currentPhone.length > 0 && line.length > 10) {
        records.push({
          name: currentName,
          phoneNumber: currentPhone,
          address: line,
          district,
          sourceUrl: this.sourceUrl,
        });
        currentName = '';
        currentPhone = '';
      }
    }

    return records;
  }

  private looksLikeDistrict(value: string): boolean {
    return value == value.toUpperCase() &&
      !/\d/.test(value) &&
      !value.includes('ECZANESI') &&
      value.length > 2 &&
      value.length < 32;
  }

  private looksLikePhone(value: string): boolean {
    return /0\s*\(?\d{3}\)?[\s-]*\d{3}[\s-]*\d{2}[\s-]*\d{2}/.test(value);
  }

  private looksLikePharmacyName(value: string): boolean {
    const upper = value.toUpperCase();
    return upper.includes('ECZANESI') || upper.includes('ECZANESİ');
  }
}
