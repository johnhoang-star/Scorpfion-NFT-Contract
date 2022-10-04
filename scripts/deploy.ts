// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  let [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
  // We get the contract to deploy
  // const provider = new ethers.providers.Web3Provider();


  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy();
  await marketplace.deployed();
  console.log("Marketplace deployed to:", marketplace.address);

  const ScorpionNFT = await ethers.getContractFactory("ScorpionNFT");
  const Scorp = await ScorpionNFT.deploy();
  // const Scorp = await ScorpionNFT.deploy(marketplace.address);
  await Scorp.deployed();
  console.log("NFT Scorp deployed to:", Scorp.address);

  await Scorp._setbaseURI("https://scorpion-finance.mypinata.cloud/ipfs/QmWPP3ZSPcaFCuG7on8YHrEbRa3QdjRgB4j9UYvpqdWJ3E/");
  await Scorp.setApprovalForAll(marketplace.address, true);
  // const owneraddr = await owner.getAddress();
  // await Scorp.setApprovalForAll(owneraddr, true);

  await marketplace.setScorp(Scorp.address);
  await marketplace.setMarketingWallet("0x8ee38219AF0E2a8Cc935E28023F1Efe32E4bFCfb");
  await marketplace.setRoyalties(5);
  await marketplace.setNFTPrice([BigNumber.from("250000000000000000"),
  BigNumber.from("750000000000000000"),BigNumber.from("1000000000000000000"),BigNumber.from("3000000000000000000")]);

  await marketplace.init(1,25,4);
  await marketplace.init(26,115,3);
  await marketplace.init(116,167,2);
  await marketplace.init(168,273,1);
  await marketplace.init(274,277,4);
  await marketplace.init(278,288,3);
  await marketplace.init(289,313,2);
  await marketplace.init(314,373,1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
