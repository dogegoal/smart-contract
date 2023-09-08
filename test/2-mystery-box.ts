import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";

import { ethers, upgrades } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
const WITHDRAWER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("WITHDRAWER"));
const MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
const BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BURNER_ROLE"));
const RANDOMNESS_REPLIER = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("RANDOMNESS_REPLIER"));

describe("Characters, Mystery Box", () => {
  let owner: SignerWithAddress,
    addr1: SignerWithAddress,
    addr2: SignerWithAddress,
    addr3: SignerWithAddress,
    addr4: SignerWithAddress,
    addr5: SignerWithAddress,
    addr6: SignerWithAddress,
    addr7: SignerWithAddress,
    addr8: SignerWithAddress,
    addr9: SignerWithAddress;

  let footieSuperstar: Contract, mysteryBox: Contract;

  const deploy = async () => {
    [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9] = await ethers.getSigners();

    const payee = owner.address;
    const feeNumerator = 500; // feeDenominator = 10000 -> 5%

    // -- FootieSuperstar
    const FootieSuperstar = await ethers.getContractFactory("FootieSuperstar");

    // -- MysteryBox
    const MysteryBox = await ethers.getContractFactory("MysteryBox");

    // SMC FootieSuperstar
    footieSuperstar = await (await upgrades.deployProxy(FootieSuperstar, [payee, feeNumerator])).deployed();

    // SMC MysteryBox
    mysteryBox = await (await upgrades.deployProxy(MysteryBox, [footieSuperstar.address])).deployed();
  };

  const footieSuperstarConfig = async () => {
    await (await footieSuperstar.setBaseURI("https://dogegoal.ai")).wait();
  };

  const grantMinterRole = async () => {
    await (await footieSuperstar.grantRole(MINTER_ROLE, mysteryBox.address)).wait();
  };

  const grantBurnerRole = async () => {
    await (await footieSuperstar.grantRole(BURNER_ROLE, owner.address)).wait();
  };

  const mysteryBoxConfig = async () => {
    await (await mysteryBox.setMintFee(1)).wait();
    await (await mysteryBox.setFootieSuperstar(footieSuperstar.address)).wait();
  };

  const grantWithdrawerRole = async () => {
    await (await mysteryBox.grantRole(WITHDRAWER_ROLE, owner.address)).wait();
  };

  const grantRandomnessReplierRole = async () => {
    await (await mysteryBox.grantRole(RANDOMNESS_REPLIER, addr1.address)).wait();
    await (await mysteryBox.grantRole(RANDOMNESS_REPLIER, addr2.address)).wait();
    await (await mysteryBox.grantRole(RANDOMNESS_REPLIER, addr3.address)).wait();
  };

  describe("Tests", () => {
    describe("Footie Superstar", () => {
      beforeEach(async () => {
        await deploy();
        await footieSuperstarConfig();
        await grantMinterRole();
        await grantBurnerRole();
      });

      it("after deploy", async () => {});
    });

    describe("Mystery Box", () => {
      beforeEach(async () => {
        await deploy();
        await footieSuperstarConfig();
        await grantMinterRole();
        await grantBurnerRole();
        await mysteryBoxConfig();
        await grantWithdrawerRole();
        await grantRandomnessReplierRole();
      });

      it("after deploy", async () => {});

      it("cannot open box", async () => {});

      it("can open box", async () => {});
    });
  });
});
