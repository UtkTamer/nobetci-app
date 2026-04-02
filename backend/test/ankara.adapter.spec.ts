import { readFileSync } from "node:fs";
import { join } from "node:path";

import { HttpService } from "@nestjs/axios";

import { AnkaraDutySourceAdapter } from "../src/sources/adapters/ankara.adapter";

describe("AnkaraDutySourceAdapter", () => {
  const htmlFixture = readFileSync(
    join(__dirname, "fixtures/edevlet-search-result.html"),
    "utf-8",
  );

  it("parses e-Devlet table rows", () => {
    const adapter = new AnkaraDutySourceAdapter({} as HttpService);

    const records = adapter.parseHtml(htmlFixture);

    expect(records).toHaveLength(2);
    expect(records[0]).toMatchObject({
      name: "NİHAL",
      district: "Fatih",
      phoneNumber: "0 - (212) 521 - 4189",
    });
    expect(records[0].address).toBe("Ali Kuşçu Mah. Başmüezzin Sok No:25/C");
    expect(records[1]).toMatchObject({
      name: "MERKEZ ECZANESİ",
      district: "Çankaya",
      phoneNumber: "0 - (312) 111 - 2233",
    });
  });
});
