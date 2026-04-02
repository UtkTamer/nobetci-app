import { readFileSync } from "node:fs";
import { join } from "node:path";

import { HttpService } from "@nestjs/axios";
import { of } from "rxjs";

import { EDevletDutySourceAdapter } from "../src/sources/edevlet-duty-source.adapter";

describe("EDevletDutySourceAdapter", () => {
  const htmlFixture = readFileSync(
    join(__dirname, "fixtures/edevlet-search-result.html"),
    "utf-8",
  );

  it("parses e-Devlet search table rows", () => {
    const adapter = new EDevletDutySourceAdapter({} as HttpService, {
      citySlug: "ankara",
      cityDisplayName: "Ankara",
      plateCode: "06",
    });

    const records = adapter.parseHtml(htmlFixture);

    expect(records).toHaveLength(2);
    expect(records[0]).toMatchObject({
      name: "NİHAL",
      district: "Fatih",
      phoneNumber: "0 - (212) 521 - 4189",
      address: "Ali Kuşçu Mah. Başmüezzin Sok No:25/C",
    });
    expect(records[1]).toMatchObject({
      name: "MERKEZ ECZANESİ",
      district: "Çankaya",
      phoneNumber: "0 - (312) 111 - 2233",
    });
  });

  it("waits for async search results before parsing", async () => {
    const initialHtml = `
      <form>
        <input type="hidden" name="token" value="{initial-token}" />
      </form>
    `;
    const queuedHtml = `
      <body data-token="{async-token}">
        <script>
          var redirectURL = 'L3NhZ2xpay10aXRjay1ub2JldGNpLWVjemFuZS1zb3JndWxhbWE/bm9iZXRjaT1FY3phbmVsZXI=';
        </script>
      </body>
    `;

    const httpService = {
      get: jest
        .fn()
        .mockImplementationOnce(() =>
          of({
            data: initialHtml,
            headers: { "set-cookie": ["session=abc; Path=/"] },
          }),
        )
        .mockImplementationOnce(() =>
          of({
            data: htmlFixture,
            headers: {},
          }),
        ),
      post: jest
        .fn()
        .mockImplementationOnce(() =>
          of({
            data: queuedHtml,
            headers: { "set-cookie": ["queue=def; Path=/"] },
          }),
        )
        .mockImplementationOnce(() =>
          of({
            data: {
              requestStatus: "FINISHED",
              redirectURL:
                "/saglik-titck-nobetci-eczane-sorgulama?nobetci=Eczaneler",
            },
            headers: {},
          }),
        ),
    } as unknown as HttpService;

    const adapter = new EDevletDutySourceAdapter(httpService, {
      citySlug: "ankara",
      cityDisplayName: "Ankara",
      plateCode: "06",
    });

    const result = await adapter.fetchAndParse();

    expect(result.records).toHaveLength(2);
    expect(httpService.post).toHaveBeenCalledTimes(2);
    expect(httpService.get).toHaveBeenCalledTimes(2);
  });
});
