import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";

import { ethers, upgrades } from "hardhat";
import { expect } from "chai";

const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));

const STARTER_PACK_ID = 1;
const STARTER_PACK_URL = "";
const STARTER_PACK_PRICE = 2;

const PRO_PACK_ID = 2;
const PRO_PACK_URL = "";
const PRO_PACK_PRICE = 2;

describe("Early Backer Pass", () => {
  it("Should purchase pack with correct price", async function () {
    const [owner, addr1] = await ethers.getSigners();

    const payee = owner.address;
    const beneficary = owner.address;
    const feeNumerator = 500; // feeDenominator = 10000 -> 5%

    // -- EarlyPass
    const EarlyPass = await ethers.getContractFactory("EarlyPass");

    // -- EarlyAccess
    const EarlyAccess = await ethers.getContractFactory("EarlyAccess");

    // SMC EarlyPass
    const earlyPass = await (await upgrades.deployProxy(EarlyPass, [payee, feeNumerator])).deployed();

    // SMC EarlyAccess
    const earlyAccess = await (await upgrades.deployProxy(EarlyAccess, [earlyPass.address, beneficary])).deployed();

    await earlyPass.grantRole(MINTER_ROLE, earlyAccess.address);

    await earlyPass.updatePassURI(STARTER_PACK_ID, STARTER_PACK_URL);
    await earlyPass.updatePassURI(PRO_PACK_ID, PRO_PACK_URL);

    await earlyAccess.setPassPrice(STARTER_PACK_ID, STARTER_PACK_PRICE);
    await earlyAccess.setPassPrice(PRO_PACK_ID, PRO_PACK_PRICE);

    // Purchase
    await expect(
      earlyAccess.connect(addr1).purchasePass(STARTER_PACK_ID, {
        value: STARTER_PACK_PRICE,
      })
    ).to.changeEtherBalance(addr1, -STARTER_PACK_PRICE);

    await expect(
      earlyAccess.connect(addr1).purchasePass(PRO_PACK_ID, {
        value: 2 * PRO_PACK_PRICE,
      })
    ).to.changeEtherBalance(addr1, -2 * PRO_PACK_PRICE);
  });
});
