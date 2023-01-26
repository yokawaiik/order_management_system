import { BigNumber } from "ethers";

export default class OrderMember {
  organizationId?: BigNumber;
  userAddress?: string;
  transferred?: boolean;
  decision?: BigNumber;

  constructor(
    organizationId: BigNumber,
    userAddress: string,
    transferred: boolean,
    decision: BigNumber
  ) {
    this.organizationId = organizationId;
    this.userAddress = userAddress;
    this.transferred = transferred;
    this.decision = decision;
  }
}
