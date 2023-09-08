import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";
import { ScriptConfig } from "./config";

const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Deploying contracts with the account: ", owner.address);
  console.log("Account balance: ", (await owner.getBalance()).toString());
  const payee = ScriptConfig.Payee ?? owner.address;
  const feeNumerator = 500; // feeDenominator = 10000 -> 5%

  const FootieSuperstar = await ethers.getContractFactory("FootieSuperstar");
  const footieSuperstar = await (await upgrades.deployProxy(FootieSuperstar, [payee, feeNumerator])).deployed();
  console.log("FootieSuperstar is deployed at: ", footieSuperstar.address);

  const MysteryBox = await ethers.getContractFactory("MysteryBox");
  const mysteryBox = await (await upgrades.deployProxy(MysteryBox, [footieSuperstar.address])).deployed();
  console.log("MysteryBox is deployed at: ", mysteryBox.address);

  // Grant minter role to MysteryBox SMC
  await footieSuperstar.grantRole(MINTER_ROLE, mysteryBox.address);
  console.log("MysteryBox now has minter role");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
