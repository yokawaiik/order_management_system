import * as fs from "fs";

const getPrivateKeyFromFile = (path: string): string => {
  console.log(path);

  let key = fs.readFileSync(path, { encoding: "utf8" });

  console.log(key);

  return key.toString();
};

export default getPrivateKeyFromFile;
