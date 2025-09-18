import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

// Måste tydligen definera enums igen här
enum SubscriptionStatus { Active, Paused }


describe("SmartSub", function() {
    async function deploySmartSubFixture() {
        const [ownerAccount, notOwner] = await ethers.getSigners();
        const SmartSub = await ethers.getContractFactory("SmartSub");
        const smartSub = await SmartSub.deploy();

        return { smartSub, ownerAccount, notOwner };
        }

describe("Deployment", function() {
            it("Should set the correct owner", async function() {
                const { smartSub, ownerAccount } = await deploySmartSubFixture();
    
                expect(await smartSub.owner()).to.equal(ownerAccount.address);
            });
        });


  describe("createSub", function () {
    it("Should create a subscription", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.nextSubscriptionId()).to.equal(0);
    });
    it("should revert if a non-owner tries to manage a sub", async function() {
        const { smartSub, notOwner } = await deploySmartSubFixture();
        const tx = await smartSub.connect(notOwner).createSub("Netflix", 100, 30 days, 0, 0);
        await expect(
          smartSub.connect(notOwner).manageSub(0, 200, 0) // 0 = SubscriptionStatus.Active
        ).to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
      });
      it("Should not create a subscription if the title is empty", async function() {
        const { smartSub, ownerAccount } = await deploySmartSubFixture();
        await expect(smartSub.createSub("", 100, 30 days, 0, 0)).to.be.revertedWithCustomError("You have to state a name for the subscription")
        it("Should not create a subscription if the cycle length is less than 1 day", async function () {
            const { smartSub, notOwner } = await deploySmartSubFixture();
        await expect(smartSub.createSub("Netflix", 100, 0, 0, 0)).to.be.revertedWithCustomError("Cycle length has to be more than just 0"); 
        });
        it("should start with nextSubscriptionId = 0", async function ()
    {
        const { smartSub, ownerAccount } = await deploySmartSubFixture();
        expect(await smartSub.nextSubscriptionId()).to.equal(0);
    }
)
")


  describe("manageSub", function () {
    it("Should not work if someone else but the owner tries to call it", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
    expect(await smartSub.manageSub(0, 100000000000000000, SubscriptionStatus.Active)).to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
    it("Should send an error message if the sub id does not exist", async function () {
        const { smartSub, notOwner } = await deploySmartSubFixture();
        await expect(smartSub.manageSub(100, 200, SubscriptionStatus.Active)).to.be.revertedWithCustomError(smartSub, "SubscriptionNotFound");
        it("Should be able to pause a sub", async function(){
            const { smartSub, notOwner } = await deploySmartSubFixture();
            await expect(smartSub.manageSub(0, 200, SubscriptionStatus.Paused))
        })
    });
  });

  describe("withdrawRevenue", function () {
    it("Should withdraw revenue to the correct address", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.withdrawRevenue(0)).to.equal(true)
      it("Should send an error message if someone else but the owner tries to call it", async function () {
        const { smartSub, notOwner } = await deploySmartSubFixture();
        await expect(smartSub.withdrawRevenue(0)).to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
      });
      it("Should send an error message if the sub id does not exist", async function () {
        const { smartSub, notOwner } = await deploySmartSubFixture();
        await expect(smartSub.withdrawRevenue(100)).to.be.revertedWithCustomError(smartSub, "SubscriptionNotFound");
      });
    });
  });

  describe("subscribe", function () {
    it("Should subscribe to said subscription id", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.subscribe(0, 100000000000000000)).to.equal(true)
      it("")
    });
  });

  describe("pauseSub", function () {
    it("Should pause a subscription", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.pauseSub(0)).to.equal(true)
    });
  });

  describe("giveawaySub", function () {
    it("Should giveaway a subscription", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.giveawaySub(0, ownerAccount.address)).to.equal(true)
    });
  });
  
  describe("checkMySubscriptionStatus", function () {
    it("Should check my subscription status", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.checkMySubscriptionStatus(0)).to.equal(true)
    });
  });
  
  describe("getSubscriptionEndDate", function () {
    it("Should get the subscription end date", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.getSubscriptionEndDate(0)).to.equal(true)
    });
  });
  
  
  
});