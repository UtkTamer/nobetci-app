import { HttpService } from "@nestjs/axios";
import { Injectable } from "@nestjs/common";

import { EDevletDutySourceAdapter } from "../edevlet-duty-source.adapter";

@Injectable()
export class IstanbulDutySourceAdapter extends EDevletDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: "istanbul",
      cityDisplayName: "İstanbul",
      plateCode: "34",
    });
  }
}
