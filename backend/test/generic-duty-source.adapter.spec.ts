import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { HttpService } from '@nestjs/axios';

import { GenericDutySourceAdapter } from '../src/sources/generic-duty-source.adapter';

describe('GenericDutySourceAdapter', () => {
  const htmlFixture = readFileSync(
    join(__dirname, 'fixtures/city-sample.html'),
    'utf-8',
  );

  it('parses district, phone and address rows', () => {
    const adapter = new GenericDutySourceAdapter({} as HttpService, {
      citySlug: 'istanbul',
      cityDisplayName: 'İstanbul',
      sourceName: 'İstanbul Eczacı Odası',
      sourceUrl: 'https://example.com',
    });

    const records = adapter.parseHtml(htmlFixture);

    expect(records).toHaveLength(2);
    expect(records[0]).toMatchObject({
      name: 'MERKEZ ECZANESI',
      district: 'KADIKOY',
      phoneNumber: '0 (216) 345 01 01',
    });
    expect(records[1].address).toContain('Moda Cad.');
  });
});
