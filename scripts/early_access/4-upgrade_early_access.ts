import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";
import { ScriptConfig } from "./config";

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Upgrade contract with the account: ", owner.address);
  console.log("Account balance: ", (await owner.getBalance()).toString());

  const EarlyAccess = await ethers.getContractFactory("EarlyAccess");
  const earlyAccess = await upgrades.upgradeProxy(ScriptConfig.EarlyAccessAddress, EarlyAccess);
  console.log("EarlyAccess upgraded", earlyAccess);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
