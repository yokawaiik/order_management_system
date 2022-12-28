import path from "path";
import getPrivateKeyFromFile from "../utils/getPrivateKeyFromFile";

const baseOwnerKeyPath =
  "blockchain/test-network/config/nodes/member1/accountPrivateKey";
const absolutePathToOwnerKey = path.join(
  __dirname,
  "..",
  "..",
  baseOwnerKeyPath
);

const OWNER_KEY = getPrivateKeyFromFile(absolutePathToOwnerKey);

export { OWNER_KEY };
