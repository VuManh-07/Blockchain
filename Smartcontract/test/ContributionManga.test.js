const { expect } = require("chai")

describe("ContributionMagane", () => {
    const deployContributionManage = async () => {
        const [owner, otherAccount] = await ethers.getSigners();

        const ContributionManage = await ethers.getContractFactory("ContributionMange");
        const contributionManage = await ContributionManage.deploy();

        return { contributionManage, owner, otherAccount }
    }

    it("Deployment", async () => {
        const { contributionManage } = await deployContributionManage();

        expect(contributionManage.target).to.not.equal(undefined)
    })

    it("Function Contribute", async () => {
        const { contributionManage, otherAccount } = await deployContributionManage();
        const amount = ethers.parseEther("0.1")

        await contributionManage.connect(otherAccount).contribute({ value: amount });

        const balanceOfContract = await ethers.provider.getBalance(contributionManage.target);

        expect(balanceOfContract).to.eq(amount);
        expect(await contributionManage.totalContributed()).to.eq(amount);
    })

    it("Function Contribute amount = 0", async () => {
        const { contributionManage, otherAccount } = await deployContributionManage();
        const amount = ethers.parseEther("0")

        const tx = contributionManage.connect(otherAccount).contribute({ value: amount });

        await expect(tx).to.be.revertedWithCustomError(contributionManage, "ZeroAmount");
    })

    it("Function withdraw", async () => {
        const { contributionManage, otherAccount } = await deployContributionManage();
        const amountContribute = ethers.parseEther("1");
        const amountWithdraw = ethers.parseEther("0.5");

        await contributionManage.connect(otherAccount).contribute({ value: amountContribute });
        await contributionManage.connect(otherAccount).withdraw(amountWithdraw);

        let balanceOfSC = await ethers.provider.getBalance(contributionManage.target);
        
        expect(balanceOfSC).to.eq(amountContribute-amountWithdraw)

    })

    it("Function withdraw amount = 0", async () => {
        const { contributionManage, otherAccount } = await deployContributionManage();
        const amount = ethers.parseEther("0")

        const tx = contributionManage.connect(otherAccount).withdraw(amount);

        await expect(tx).to.be.revertedWithCustomError(contributionManage, "ZeroAmount");
    })

    it("Function withdraw amount > amout contribute", async () => {
        const { contributionManage, otherAccount } = await deployContributionManage();
        const amount = ethers.parseEther("0.1")

        const tx = contributionManage.connect(otherAccount).withdraw(amount);

        await expect(tx).to.be.revertedWithCustomError(contributionManage, "InsufficientBalance");
    })
})