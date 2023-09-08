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
  const beneficary = ScriptConfig.Beneficary ?? owner.address;
  const feeNumerator = 500; // feeDenominator = 10000 -> 5%

  // Deploy
  const EarlyPass = await ethers.getContractFactory("EarlyPass");
  const earlyPass = await upgrades.deployProxy(EarlyPass, [payee, feeNumerator]);
  console.log("EarlyPass is deployed at: ", earlyPass.address);

  const EarlyAccess = await ethers.getContractFactory("EarlyAccess");
  const earlyAccess = await upgrades.deployProxy(EarlyAccess, [earlyPass.address, beneficary]);
  console.log("EarlyAccess is deployed at: ", earlyAccess.address);

  // Grant minter role to EarlyAccess SMC
  await earlyPass.grantRole(MINTER_ROLE, earlyAccess.address);
  console.log("EarlyAccess now has minter role");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
