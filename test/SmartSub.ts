import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

// Måste tydligen definera enums igen här
enum SubscriptionStatus { Active, Paused }

// Deployment-tester 
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
    // Testar att sub skapas
    it("Should create a subscription", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.nextSubscriptionId()).to.equal(0);
      
      await smartSub.createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      expect(await smartSub.nextSubscriptionId()).to.equal(1);
    });

    it("Should start with nextSubscriptionId = 0", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.nextSubscriptionId()).to.equal(0);
    });

    it("Should increment nextSubscriptionId after each new sub", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      expect(await smartSub.nextSubscriptionId()).to.equal(0);
      
      await smartSub.createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      expect(await smartSub.nextSubscriptionId()).to.equal(1);
      
      await smartSub.createSub("Spotify", ethers.parseEther("0.05"), 86400, 0, 0);
      expect(await smartSub.nextSubscriptionId()).to.equal(2);
    });

    it("Should not create a subscription if the title is empty", async function() {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      await expect(smartSub.createSub("", ethers.parseEther("0.1"), 86400, 0, 0))
        .to.be.revertedWith("You have to give the service subscription a name or title.");
    });

    it("Should not create a subscription if the cycle length is 0", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      await expect(smartSub.createSub("Netflix", ethers.parseEther("0.1"), 0, 0, 0))
        .to.be.revertedWith("Cycle length must be greater than 0.");
    });
  });


  describe("manageSub", function () {
    it("Should revert if a non-owner tries to manage a sub", async function() {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      // Skapa en prenumeration först
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
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
      await smartSub.createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
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
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
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
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      // Prenumerera för att få balans
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      // Kolla att balansen finns
      expect(await smartSub.balances(ownerAccount.address)).to.equal(ethers.parseEther("0.1"));
      
      // Ta ut pengarna
      await smartSub.connect(ownerAccount).withdrawRevenue(0);
      
      // Balansen ska nu vara 0
      expect(await smartSub.balances(ownerAccount.address)).to.equal(0);
    });
  });

  describe("subscribe", function () {
    it("Should allow a user to subscribe by paying exact fee", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      // Skapa prenumeration
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      // Prenumerera
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.true;
    });

    it("Should increase owner's balance when user subscribes", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      expect(await smartSub.balances(ownerAccount.address)).to.equal(0);
      
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.balances(ownerAccount.address)).to.equal(ethers.parseEther("0.1"));
    });

    it("Should store subscription start date for user", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      const startTime = await smartSub.userSubscriptionStart(notOwner.address, 0);
      expect(startTime).to.be.greaterThan(0);
    });

    it("Should emit SubscribedToSub when successful", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") }))
        .to.emit(smartSub, "SubscribedToSub")
        .withArgs(0, notOwner.address);
    });

    it("Should revert if subscription does not exist", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await expect(smartSub.connect(notOwner).subscribe(999, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") }))
        .to.be.revertedWithCustomError(smartSub, "SubscriptionNotFound");
    });

    it("Should revert if subscription is paused", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(ownerAccount).manageSub(0, ethers.parseEther("0.1"), SubscriptionStatus.Paused);
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") }))
        .to.be.revertedWithCustomError(smartSub, "SubIsPausedError");
    });

    it("Should revert if already subscribed", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") }))
        .to.be.revertedWithCustomError(smartSub, "AlreadySubscribedError");
    });

    it("Should revert if sent ETH is less than fee", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.05"), { value: ethers.parseEther("0.05") }))
        .to.be.revertedWithCustomError(smartSub, "NotEnoughETHError");
    });

    it("Should revert if fee argument does not match msg.value", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      await expect(smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.2") }))
        .to.be.revertedWith("The ETH amount sent must match the fee parameter.");
    });
  });

  describe("pauseSub", function () {
    it("Should set userSubscriptions mapping to false", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
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

    it("Should revert if user is not subscribed", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      await expect(smartSub.connect(notOwner).pauseSub(0))
        .to.be.revertedWithCustomError(smartSub, "NotSubscribedError");
    });
  });

  describe("giveawaySub", function () {
    it("Should let a user transfer their subscription to another address", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      await smartSub.connect(notOwner).giveawaySub(0, thirdUser.address);
      
      expect(await smartSub.userSubscriptions(thirdUser.address, 0)).to.be.true;
    });

    it("Should set original userSubscriptions mapping to false", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.true;
      
      await smartSub.connect(notOwner).giveawaySub(0, thirdUser.address);
      
      expect(await smartSub.userSubscriptions(notOwner.address, 0)).to.be.false;
    });

    it("Should set new userSubscriptions mapping to true", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      expect(await smartSub.userSubscriptions(thirdUser.address, 0)).to.be.false;
      
      await smartSub.connect(notOwner).giveawaySub(0, thirdUser.address);
      
      expect(await smartSub.userSubscriptions(thirdUser.address, 0)).to.be.true;
    });

    it("Should preserve the original start date when given away", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      const originalStartTime = await smartSub.userSubscriptionStart(notOwner.address, 0);
      
      await smartSub.connect(notOwner).giveawaySub(0, thirdUser.address);
      
      const newStartTime = await smartSub.userSubscriptionStart(thirdUser.address, 0);
      expect(newStartTime).to.equal(originalStartTime);
    });

    it("Should revert if user is not subscribed", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      const [, , thirdUser] = await ethers.getSigners();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      await expect(smartSub.connect(notOwner).giveawaySub(0, thirdUser.address))
        .to.be.revertedWithCustomError(smartSub, "NotSubscribedError");
    });
  });
  
  describe("checkMySubscriptionStatus", function () {
    it("Should return correct status message for existing subscription", async function () {
      const { smartSub, ownerAccount, notOwner } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      const status = await smartSub.connect(notOwner).checkMySubscriptionStatus(0);
      expect(status).to.equal("No, you do not have this subscription.");
      
      await smartSub.connect(notOwner).subscribe(0, ethers.parseEther("0.1"), { value: ethers.parseEther("0.1") });
      
      const statusAfter = await smartSub.connect(notOwner).checkMySubscriptionStatus(0);
      expect(statusAfter).to.equal("Yes, you are subscribed to this service.");
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
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, endDate, 0);
      
      const returnedEndDate = await smartSub.getSubscriptionEndDate(0);
      expect(returnedEndDate).to.equal(endDate);
    });

    it("Should return 0 for never-ending subscription", async function () {
      const { smartSub, ownerAccount } = await deploySmartSubFixture();
      
      await smartSub.connect(ownerAccount).createSub("Netflix", ethers.parseEther("0.1"), 86400, 0, 0);
      
      const endDate = await smartSub.getSubscriptionEndDate(0);
      expect(endDate).to.equal(0);
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