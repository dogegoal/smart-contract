import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";

const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));

async function main() {
  const [owner] = await ethers.getSigners();
  console.log("Deploying contracts with the account: ", owner.address);
  console.log("Account balance: ", (await owner.getBalance()).toString());
  const payee = owner.address;
  const beneficary = owner.address;
  const feeNumerator = 500; // feeDenominator = 10000 -> 5%

  // Deploy
  const EarlyPack = await ethers.deployContract("EarlyPack");
  await EarlyPack.initialize(payee, feeNumerator);
  console.log("EarlyPack is deployed at: ", EarlyPack.address);

  const EarlyAccess = await ethers.deployContract("EarlyAccess");
  await EarlyAccess.initialize(EarlyPack.address, beneficary);
  console.log("EarlyAccess is deployed at: ", EarlyAccess.address);

  // Grant minter role to EarlyAccess SMC
  await EarlyPack.grantRole(MINTER_ROLE, EarlyAccess.address);
  console.log("EarlyPack now has minter role");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
