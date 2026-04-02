import { HttpService } from "@nestjs/axios";
import { Injectable } from "@nestjs/common";

import { EDevletDutySourceAdapter } from "../edevlet-duty-source.adapter";

@Injectable()
export class BursaDutySourceAdapter extends EDevletDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: "bursa",
      cityDisplayName: "Bursa",
      plateCode: "16",
    });
  }
}
