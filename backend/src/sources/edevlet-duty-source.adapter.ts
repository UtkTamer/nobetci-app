import { HttpService } from "@nestjs/axios";
import { Injectable } from "@nestjs/common";
import * as cheerio from "cheerio";
import { firstValueFrom } from "rxjs";

import {
  CitySlug,
  DutySourceAdapter,
  ParsedCityResult,
  RawPharmacyRecord,
} from "../common/types";

interface EDevletAdapterConfig {
  citySlug: CitySlug;
  cityDisplayName: string;
  plateCode: string;
}

interface EDevletSession {
  cookieHeader: string;
  token: string;
}

interface EDevletSearchState {
  asyncToken: string | null;
  redirectUrl: string | null;
  cookieHeader: string;
}

@Injectable()
export class EDevletDutySourceAdapter implements DutySourceAdapter {
  constructor(
    private readonly httpService: HttpService,
    private readonly config: EDevletAdapterConfig,
  ) {}

  readonly sourceName = "e-Devlet / TİTCK";
  readonly sourceUrl =
    "https://www.turkiye.gov.tr/saglik-titck-nobetci-eczane-sorgulama";

  get citySlug() {
    return this.config.citySlug;
  }

  get cityDisplayName() {
    return this.config.cityDisplayName;
  }

  async fetchAndParse(): Promise<ParsedCityResult> {
    const fetchedAt = new Date();
    const session = await this.startSession();
    const dutyDate = this.formatDutyDate(fetchedAt);

    const searchState = await this.submitSearchForm(
      session.cookieHeader,
      session.token,
      dutyDate,
    );
    const resultsPath = await this.waitForResults(searchState);
    const html = await this.fetchResultsHtml(
      searchState.cookieHeader,
      resultsPath,
    );

    return {
      citySlug: this.citySlug,
      cityDisplayName: this.cityDisplayName,
      source: this.sourceName,
      fetchedAt,
      records: this.parseHtml(html),
    };
  }

  parseHtml(html: string): RawPharmacyRecord[] {
    const $ = cheerio.load(html);
    const rows = $("#searchTable tr").toArray();
    const records: RawPharmacyRecord[] = [];

    for (const row of rows) {
      const columns = $(row).find("td");
      if (columns.length < 4) {
        continue;
      }

      const name = this.cleanText(columns.eq(0).text());
      const district = this.cleanText(columns.eq(1).text());
      const phoneNumber = this.cleanPhone(columns.eq(2).text());
      const address = this.cleanText(columns.eq(3).text());

      if (name.length === 0 || address.length === 0) {
        continue;
      }

      records.push({
        name,
        district,
        phoneNumber,
        address,
        sourceUrl: this.sourceUrl,
      });
    }

    return records;
  }

  private async startSession(): Promise<EDevletSession> {
    const response = await firstValueFrom(
      this.httpService.get<string>(this.sourceUrl, {
        responseType: "text" as never,
        headers: this.defaultHeaders(),
      }),
    );

    const token = this.extractToken(response.data);
    if (token == null) {
      throw new Error(`Failed to extract e-Devlet token for ${this.citySlug}`);
    }

    return {
      token,
      cookieHeader: this.extractCookieHeader(response.headers["set-cookie"]),
    };
  }

  private async submitSearchForm(
    cookieHeader: string,
    token: string,
    dutyDate: string,
  ): Promise<EDevletSearchState> {
    const body = new URLSearchParams({
      plakaKodu: this.config.plateCode,
      nobetTarihi: dutyDate,
      token,
      btn: "Sorgula",
    }).toString();

    const response = await firstValueFrom(
      this.httpService.post<string>(`${this.sourceUrl}?submit`, body, {
        responseType: "text" as never,
        headers: {
          ...this.defaultHeaders(),
          "Content-Type": "application/x-www-form-urlencoded",
          Cookie: cookieHeader,
        },
      }),
    );

    const nextCookieHeader = this.mergeCookieHeaders(
      cookieHeader,
      this.extractCookieHeader(response.headers["set-cookie"]),
    );

    return {
      cookieHeader: nextCookieHeader,
      asyncToken: this.extractBodyToken(response.data),
      redirectUrl: this.extractRedirectUrl(response.data),
    };
  }

  private async waitForResults(state: EDevletSearchState): Promise<string> {
    if (state.asyncToken == null || state.redirectUrl == null) {
      return `${this.sourceUrl}?nobetci=Eczaneler`;
    }

    const maxAttempts = 20;
    const delayMs = 3000;

    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      if (attempt > 0) {
        await EDevletDutySourceAdapter.sleep(delayMs);
      }

      const response = await firstValueFrom(
        this.httpService.post<{
          requestStatus?: string;
          redirectURL?: string;
        }>(
          `${this.sourceUrl}?nobetci=Eczaneler&submit`,
          new URLSearchParams({
            ajax: "1",
            token: state.asyncToken,
            asyncQueue: "",
            redirectURL: state.redirectUrl,
          }).toString(),
          {
            responseType: "json" as never,
            headers: {
              ...this.defaultHeaders(),
              "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
              "X-Requested-With": "XMLHttpRequest",
              Cookie: state.cookieHeader,
              Referer: `${this.sourceUrl}?nobetci=Eczaneler`,
            },
          },
        ),
      );

      if (response.data?.requestStatus === "FINISHED") {
        const redirectUrl = response.data.redirectURL;
        if (typeof redirectUrl === "string" && redirectUrl.length > 0) {
          return this.toAbsoluteUrl(redirectUrl);
        }

        return `${this.sourceUrl}?nobetci=Eczaneler`;
      }
    }

    throw new Error(
      `Timed out while waiting e-Devlet results for ${this.citySlug} after ${maxAttempts} attempts`,
    );
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  private async fetchResultsHtml(
    cookieHeader: string,
    resultsUrl: string,
  ): Promise<string> {
    const response = await firstValueFrom(
      this.httpService.get<string>(resultsUrl, {
        responseType: "text" as never,
        headers: {
          ...this.defaultHeaders(),
          Cookie: cookieHeader,
        },
      }),
    );

    return response.data;
  }

  private extractToken(html: string): string | null {
    const match = html.match(/name="token"\s+value="([^"]+)"/i);
    return match?.[1] ?? null;
  }

  private extractBodyToken(html: string): string | null {
    const match = html.match(/<body[^>]*data-token="([^"]+)"/i);
    return match?.[1] ?? null;
  }

  private extractRedirectUrl(html: string): string | null {
    const match = html.match(/var redirectURL = '([^']+)'/i);
    return match?.[1] ?? null;
  }

  private toAbsoluteUrl(pathOrUrl: string): string {
    if (pathOrUrl.startsWith("http://") || pathOrUrl.startsWith("https://")) {
      return pathOrUrl;
    }

    return new URL(pathOrUrl, this.sourceUrl).toString();
  }

  private extractCookieHeader(setCookieHeader: string[] | undefined): string {
    if (setCookieHeader == null || setCookieHeader.length === 0) {
      return "";
    }

    return setCookieHeader
      .map((cookie) => cookie.split(";", 1)[0]?.trim() ?? "")
      .filter((cookie) => cookie.length > 0)
      .join("; ");
  }

  private mergeCookieHeaders(existing: string, next: string): string {
    const cookieMap = new Map<string, string>();

    for (const source of [existing, next]) {
      for (const cookie of source.split(";")) {
        const trimmed = cookie.trim();
        if (trimmed.length === 0) {
          continue;
        }

        const separatorIndex = trimmed.indexOf("=");
        if (separatorIndex < 1) {
          continue;
        }

        const key = trimmed.slice(0, separatorIndex).trim();
        cookieMap.set(key, trimmed.slice(separatorIndex + 1).trim());
      }
    }

    return [...cookieMap.entries()]
      .map(([key, value]) => `${key}=${value}`)
      .join("; ");
  }

  private formatDutyDate(value: Date): string {
    const formatter = new Intl.DateTimeFormat("tr-TR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
      timeZone: "Europe/Istanbul",
    });
    const parts = formatter.formatToParts(value);
    const day = parts.find((part) => part.type === "day")?.value ?? "";
    const month = parts.find((part) => part.type === "month")?.value ?? "";
    const year = parts.find((part) => part.type === "year")?.value ?? "";

    return `${day}/${month}/${year}`;
  }

  private cleanText(value: string): string {
    return value.replace(/\s+/g, " ").trim();
  }

  private cleanPhone(value: string): string {
    return this.cleanText(value)
      .replace(/\bAra\b/gi, "")
      .trim();
  }

  private defaultHeaders() {
    return {
      Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
    };
  }
}
