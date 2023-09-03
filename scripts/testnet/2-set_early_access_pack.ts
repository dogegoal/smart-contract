import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";

const STARTER_PACK_ID = 1;
const STARTER_PACK_URL = "https://staging-8y1a.dogegoal.ai/ticket1.webm";
const STARTER_PACK_PRICE = ethers.utils.parseUnits("0.025", "ether");

const PRO_PACK_ID = 2;
const PRO_PACK_URL = "https://staging-8y1a.dogegoal.ai/ticket2.webm";
const PRO_PACK_PRICE = ethers.utils.parseUnits("0.079", "ether");

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Account balance: ", (await owner.getBalance()).toString());

  // Set URIs
  const EarlyPack = await ethers.getContractFactory("EarlyPack");
  const earlyPack = EarlyPack.attach("0x775AaEf1626Df13cC810b16456A0354CB79a5FF8");
  console.log("Update starter pack url to: ", STARTER_PACK_URL);
  await earlyPack.updatePackURI(STARTER_PACK_ID, STARTER_PACK_URL);

  console.log("Update pro pack url to: ", PRO_PACK_URL);
  await earlyPack.updatePackURI(PRO_PACK_ID, PRO_PACK_URL);

  // Set Price
  const EarlyAccess = await ethers.getContractFactory("EarlyAccess");
  const earlyAccess = EarlyAccess.attach("0x2f633CC08a53D21EdB30935Bb306AA32b612e913");

  console.log("Update starter pack price to: ", STARTER_PACK_PRICE);
  await earlyAccess.setPackPrice(STARTER_PACK_ID, STARTER_PACK_PRICE);

  console.log("Update pro pack price to: ", PRO_PACK_PRICE);
  await earlyAccess.setPackPrice(PRO_PACK_ID, PRO_PACK_PRICE);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
