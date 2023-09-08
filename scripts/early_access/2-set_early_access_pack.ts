import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";
import { ScriptConfig } from "./config";

const STARTER_PACK_ID = 1;
const STARTER_PACK_URL = "https://dogegoal.ai/assets/early_starter_pass.json";
const STARTER_PACK_PRICE = ethers.utils.parseUnits(ScriptConfig.EarlyStarterPassPrice, "ether");

const PRO_PACK_ID = 2;
const PRO_PACK_URL = "https://dogegoal.ai/assets/early_pro_pass.json";
const PRO_PACK_PRICE = ethers.utils.parseUnits(ScriptConfig.EarlyProPassPrice, "ether");

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Account balance: ", (await owner.getBalance()).toString());

  // Set URIs
  const EarlyPass = await ethers.getContractFactory("EarlyPass");
  const earlyPass = EarlyPass.attach(ScriptConfig.EarlyPassAddress);
  console.log("Update starter pass url to: ", STARTER_PACK_URL);
  await earlyPass.updatePassURI(STARTER_PACK_ID, STARTER_PACK_URL);

  console.log("Update pro pass url to: ", PRO_PACK_URL);
  await earlyPass.updatePassURI(PRO_PACK_ID, PRO_PACK_URL);

  // Set Price
  const EarlyAccess = await ethers.getContractFactory("EarlyAccess");
  const earlyAccess = EarlyAccess.attach(ScriptConfig.EarlyAccessAddress);

  console.log("Update starter pass price to: ", STARTER_PACK_PRICE);
  await earlyAccess.setPassPrice(STARTER_PACK_ID, STARTER_PACK_PRICE);

  console.log("Update pro pass price to: ", PRO_PACK_PRICE);
  await earlyAccess.setPassPrice(PRO_PACK_ID, PRO_PACK_PRICE);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
