import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { expect } from "chai";
import { Overrides, PayableOverrides } from "ethers";
import { ethers } from "hardhat";
import {
  Marketplace,
  Marketplace__factory,
  NFT,
  NFT__factory,
} from "../typechain";
import { MSPC__factory } from "../typechain/factories/MSPC__factory";
import { USDT__factory } from "../typechain/factories/USDT__factory";
import { MSPC } from "../typechain/MSPC";
import { USDT } from "../typechain/USDT";

describe("Contract", function () {
  let mspc: MSPC;
  let usdt: USDT;

  let marketplace: Marketplace;
  let nft: NFT;

  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let addrs: SignerWithAddress[];

  beforeEach(async function () {
    // Get the Signers here.
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    mspc = await new MSPC__factory(owner).deploy();
    await mspc.deployed();

    usdt = await new USDT__factory(owner).deploy();
    await marketplace.deployed();

    marketplace = await new Marketplace__factory(owner).deploy(
      mspc.address,
      usdt.address
    );
    await marketplace.deployed();

    nft = await new NFT__factory(owner).deploy(marketplace.address);
    await nft.deployed();
  });

  describe("Marketplace", function () {
    it("Should deployed successfully", function () {
      expect(marketplace.address).to.be.properAddress;
    });
    it("Should return the right's owner", async function () {
      const marketplaceOwner = await marketplace.owner();
      expect(marketplaceOwner).to.eq(owner.address);
    });

    describe("Market Items", function () {
      beforeEach(async function () {
        for (let i = 0; i < 100; i++) {
          await nft.connect(owner).mintToken(`https://url/${i}.png`);
          await marketplace.createMarketItem(
            nft.address,
            i,
            ethers.utils.parseEther("1.0")
          );
        }
      });

      it("Should fetch the market items", async function () {
        const marketItems = await marketplace.fetchMarketItems();
        for (let i = 0; i < 10; i++) {
          const rand = Math.floor(Math.random() * 100);

          expect(marketItems[rand].nftContract).to.eq(nft.address);
          expect(marketItems[rand].sold).to.eq(false);
          expect(marketItems[rand].price).to.eq(ethers.utils.parseEther("1.0"));
          expect(marketItems[rand].tokenId).to.eq(ethers.BigNumber.from(rand));
        }
      });

      it("Should reverted with msg: Not enough token", async function () {
        let overrides: PayableOverrides = {
          value: ethers.utils.parseEther("30"),
        };
        await expect(
          marketplace.purchaseMarketItemByMspc(
            nft.address,
            ethers.BigNumber.from(22),
            overrides
          )
        ).revertedWith("Not enough token");
      });

      it.only("Should change the state after market item is purchased", async function () {
        // prev stats
        const prevMarketItems = await marketplace.fetchMarketItems();

        const prevOwner = prevMarketItems[22].owner;

        let overrides: PayableOverrides = {
          value: ethers.utils.parseEther("30"),
        };

        await marketplace
          .connect(addr1)
          .purchaseMarketItemByMspc(
            nft.address,
            ethers.BigNumber.from(22),
            overrides
          );

        const newMarketItems = await marketplace.fetchMarketItems();
        const newOwner = newMarketItems[22].owner;

        expect(newOwner).to.eq(addr1.address);
      });

      it("Should emit the event when market item is created succesfully", async function () {
        await nft.connect(owner).mintToken(`https://url/${100}.png`);
        await expect(marketplace.mintMarketItem(nft.address, 100, 500)).to.emit(
          marketplace,
          "MarketItemMinted"
        );
      });
    });
  });

  describe("NFT", function () {
    it("Should deployed successfully", function () {
      expect(nft.address).to.be.properAddress;
    });
    it("Should return marketplace's address", async function () {
      const marketplaceAddress = await nft.marketplaceAddress();
      expect(marketplaceAddress).to.eq(marketplace.address);
    });
    it("Should return correct symbol", async function () {
      expect(await nft.symbol()).to.eq("MF");
    });
    it("Should return correct name", async function () {
      expect(await nft.name()).to.eq("MonProfile");
    });

    it("should return URI with ID: 99 after minted 99 Token", async () => {
      for (let i = 0; i < 100; i++) {
        await nft.connect(owner).mintToken(`https://url/${i}.png`);
      }
      const tokenURI = await nft.tokenURI(ethers.BigNumber.from(99));
      expect(tokenURI).to.eq("https://url/99.png");
    });

    it("should revert the error message: ERC721URIStorage: URI query for nonexistent token", async function () {
      for (let i = 0; i < 100; i++) {
        await nft.connect(owner).mintToken(`https://url/${i}.png`);
      }
      // const response = await nft.tokenURI(ethers.BigNumber.from(100));
      await expect(nft.tokenURI(ethers.BigNumber.from(100))).to.be.revertedWith(
        "ERC721URIStorage: URI query for nonexistent token"
      );
    });
  });
});
