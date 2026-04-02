import { HttpService } from "@nestjs/axios";
import { Injectable } from "@nestjs/common";

import { EDevletDutySourceAdapter } from "../edevlet-duty-source.adapter";

@Injectable()
export class AnkaraDutySourceAdapter extends EDevletDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: "ankara",
      cityDisplayName: "Ankara",
      plateCode: "6",
    });
  }
}
