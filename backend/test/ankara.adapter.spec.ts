import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { HttpService } from '@nestjs/axios';

import { AnkaraDutySourceAdapter } from '../src/sources/adapters/ankara.adapter';

describe('AnkaraDutySourceAdapter', () => {
  const htmlFixture = readFileSync(
    join(__dirname, 'fixtures/ankara-iframe-sample.html'),
    'utf-8',
  );

  it('parses eczaneler.gen.tr iframe rows', () => {
    const adapter = new AnkaraDutySourceAdapter({} as HttpService);

    const records = adapter.parseHtml(htmlFixture);

    expect(records).toHaveLength(2);
    expect(records[0]).toMatchObject({
      name: 'Safirtepe Eczanesi',
      district: 'Çankaya',
      phoneNumber: '0 (312) 285-32-33',
      latitude: 39.909045,
      longitude: 32.755665,
    });
    expect(records[0].address).toBe(
      'Mustafa Kemal Mahallesi, Dumlupınar Bulvarı No:266/B-12 Çankaya / Ankara',
    );
    expect(records[1]).toMatchObject({
      name: 'Temelli Pınar Eczanesi',
      district: 'Sincan',
      latitude: null,
      longitude: null,
    });
  });
});
