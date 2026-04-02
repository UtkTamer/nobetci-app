import { HttpService } from "@nestjs/axios";
import { Injectable } from "@nestjs/common";

import { EDevletDutySourceAdapter } from "../edevlet-duty-source.adapter";

@Injectable()
export class AntalyaDutySourceAdapter extends EDevletDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: "antalya",
      cityDisplayName: "Antalya",
      plateCode: "7",
    });
  }
}
