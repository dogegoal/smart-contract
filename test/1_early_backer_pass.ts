import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
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

    const EarlyPack = await ethers.deployContract("EarlyPack");
    await EarlyPack.initialize(payee, feeNumerator);
    const EarlyAccess = await ethers.deployContract("EarlyAccess");
    await EarlyAccess.initialize(EarlyPack.address, beneficary);

    await EarlyPack.grantRole(MINTER_ROLE, EarlyAccess.address);

    await EarlyPack.updatePackURI(STARTER_PACK_ID, STARTER_PACK_URL);
    await EarlyPack.updatePackURI(PRO_PACK_ID, PRO_PACK_URL);

    await EarlyAccess.setPackPrice(STARTER_PACK_ID, STARTER_PACK_PRICE);
    await EarlyAccess.setPackPrice(PRO_PACK_ID, PRO_PACK_PRICE);

    // Purchase
    await expect(
      EarlyAccess.connect(addr1).purchasePack(STARTER_PACK_ID, {
        value: STARTER_PACK_PRICE,
      })
    ).to.changeEtherBalance(addr1, -STARTER_PACK_PRICE);

    await expect(
      EarlyAccess.connect(addr1).purchasePack(PRO_PACK_ID, {
        value: 2 * PRO_PACK_PRICE,
      })
    ).to.changeEtherBalance(addr1, -2 * PRO_PACK_PRICE);
  });
});
