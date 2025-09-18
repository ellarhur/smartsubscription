import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

// Måste definera enums igen här
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

    it("Should start with nextSubscriptionId = 0", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.nextSubscriptionId()).to.equal(0);
    });

    it("Should not create a subscription if the cycle length is 0", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      await expect(smartSub.createSub("Netflix", ethers.parseEther("0.1"), 0, 0))
        .to.be.revertedWith("Cycle length must be greater than 0.");
    });
  });


  describe("manageSub", function () {
    it("Should revert if a non-owner tries to manage a sub", async function() {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      // Skapa en prenumeration först
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      
      await expect(
        smartSub.connect(notOwner).manageSub(0, ethers.parseEther("0.2"), SubscriptionStatus.Active)
      ).to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
    });

    it("Should send an error message if the sub id does not exist", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      // För icke-existerande subscription får vi OnlySubOwnerError eftersom ownerAddress är 0x0
      await expect(smartSub.manageSub(100, ethers.parseEther("0.2"), SubscriptionStatus.Active))
        .to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
    });

    it("Should be able to pause a sub", async function(){
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      // Skapa en prenumeration först
      await smartSub.createSub("Spotify", ethers.parseEther("0.1"), 86400, 0);
      
      // Pausa prenumerationen
      await smartSub.manageSub(0, ethers.parseEther("0.1"), SubscriptionStatus.Paused);
      
      const subscription = await smartSub.subscriptions(0);
      expect(subscription.status).to.equal(SubscriptionStatus.Paused);
    });
  });

  describe("withdrawRevenue", function () {
    it("Should send an error message if someone else but the owner tries to call it", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      // Skapa en prenumeration först
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      
      await expect(smartSub.connect(notOwner).withdrawRevenue(0))
        .to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
    });

    it("Should send an error message if the sub id does not exist", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      await expect(smartSub.withdrawRevenue(100))
        .to.be.revertedWithCustomError(smartSub, "OnlySubOwnerError");
    });

    it("Should set balance to 0 after withdrawal (reentrancy protection)", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      // Skapa prenumeration
      await smartSub.connect(ownerAccount).createSub("Spotify", ethers.parseEther("0.1"), 86400, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      expect(await smartSub.subscriptionBalances(0)).to.equal(ethers.parseEther("0.1"));
      await smartSub.connect(ownerAccount).withdrawRevenue(0);
      expect(await smartSub.subscriptionBalances(0)).to.equal(0);
    });
  });

  describe("subscribe", function () {

    it("Should increase owner's balance when user subscribes", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      
      expect(await smartSub.subscriptionBalances(0)).to.equal(0);
      
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.subscriptionBalances(0)).to.equal(ethers.parseEther("0.1"));
    });

    it("Should revert if already subscribed", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") }))
        .to.be.revertedWithCustomError(smartSub, "AlreadySubscribedError");
    });

    it("Should revert if fee argument does not match msg.value", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.2") }))
        .to.be.revertedWith("The ETH amount sent must match the fee parameter.");
    });
  });

  describe("pauseSub", function () {
    it("Should set userSubscriptions mapping to false", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.true;
      
      await smartSub.connect(notOwner).pauseSub(0);
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.false;
    });

    it("Should revert if subscription does not exist", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await expect(smartSub.connect(notOwner).pauseSub(999))
        .to.be.revertedWithCustomError(smartSub, "SubscriptionNotFound");
    });
  });

  describe("giveawaySub", function () {
    it("Should set original userSubscriptions mapping to false", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.true;
      
      await smartSub.connect(notOwner).giveawaySub(0, thirdUser.address);
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.false;
    });

    it("Should set new userSubscriptions mapping to true", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.userSubscriptions(thirdUser.address, 0)).to.be.false;
      
      await smartSub.connect(notOwner).giveawaySub(0, thirdUser.address);
      
      expect(await smartSub.userSubscriptions(thirdUser.address, 0)).to.be.true;
    });
  });
  
  describe("checkMySubscriptionStatus", function () {
    it("Should return correct status message for existing subscription", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      
      const status = await smartSub.connect(notOwner).checkMySubscriptionStatus(0);
      expect(status).to.equal("No, you do not have this subscription.");
      
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      const statusAfter = await smartSub.connect(notOwner).checkMySubscriptionStatus(0);
      expect(statusAfter).to.equal("Yes, you have an active subscription to this service.");
    });

    it("Should return error message for non-existent subscription", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      const status = await smartSub.connect(notOwner).checkMySubscriptionStatus(999);
      expect(status).to.equal("This subscription does not exist.");
    });
  });
  
  describe("getSubscriptionEndDate", function () {
    it("Should return the correct end date", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      const endDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, endDate);
      
      // Testa att få tjänstens slutdatum direkt från subscription struct
      const subscription = await smartSub.subscriptions(0);
      expect(subscription.endDate).to.equal(endDate);
    });

    it("Should return 0 for never-ending subscription", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0);
      
      // Testa att slutdatum är 0 för oändliga prenumerationer
      const subscription = await smartSub.subscriptions(0);
      expect(subscription.endDate).to.equal(0);
    });
  });
  
  describe("fallback", function(){
    it("Should revert and emit FallbackCalled when calling a non-existent function", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      // Skapa en ogiltig function call med random data
      const nonExistentCall = "0x12345678"; // Random function selector
      
      await expect(ownerAccount.sendTransaction({
        to: await smartSub.getAddress(),
        data: nonExistentCall
      })).to.be.revertedWith("The function you called does not exist, try another one.");
    });

    it("Should revert and refund ETH if ETH sent to receive()", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      await expect(ownerAccount.sendTransaction({
        to: await smartSub.getAddress(),
        value: ethers.parseEther("1.0")
      })).to.be.revertedWith("This function does not exist, ETH is returned to you.");
    });
  })
});