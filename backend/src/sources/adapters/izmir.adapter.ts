import { HttpService } from "@nestjs/axios";
import { Injectable } from "@nestjs/common";

import { EDevletDutySourceAdapter } from "../edevlet-duty-source.adapter";

@Injectable()
export class IzmirDutySourceAdapter extends EDevletDutySourceAdapter {
  constructor(httpService: HttpService) {
    super(httpService, {
      citySlug: "izmir",
      cityDisplayName: "İzmir",
      plateCode: "35",
    });
  }
}
