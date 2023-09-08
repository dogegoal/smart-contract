import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";
import { ScriptConfig } from "./config";

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Account balance: ", (await owner.getBalance()).toString());

  // Set Price
  const EarlyAccess = await ethers.getContractFactory("EarlyAccess");
  const earlyAccess = EarlyAccess.attach(ScriptConfig.EarlyAccessAddress);
  await earlyAccess.pause();
  // await earlyAccess.unpause();

  console.log("Pause Early Access");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
