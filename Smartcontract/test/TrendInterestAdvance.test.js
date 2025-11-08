const { expect } = require("chai")

describe("TrendInterestAdvance", function () {
    const deployTrendInterest = async () => {
        const [owner, otherAccount] = await ethers.getSigners();
        const TrendInterest = await ethers.getContractFactory("TrendInterestAdvance");
        const trendInterest = await TrendInterest.deploy();

        return { trendInterest, owner, otherAccount }
    }

    describe("Deployment", () => {
        it("Should deploy sc success", async () => {
            const { trendInterest } = await deployTrendInterest();

            expect(trendInterest.target).to.not.equal(undefined)
        })
    })

    describe("Function", () => {
        it("Should Register success", async () => {
            const { trendInterest } = await deployTrendInterest();
            const data = { email: "manhvd1507@gmail.com", trend: "Bitcoin" };

            await trendInterest.registerInterest(data.email, data.trend);

            const interest = await trendInterest.interests(0);
            expect(interest[1]).to.equal(data.email)
            expect(interest[2]).to.equal(data.trend)
        })

        it("Should GetTrendInterest success", async () => {
            const { trendInterest, owner } = await deployTrendInterest();
            const data = [{ email: "manhvd07@gmail.com", trend: "Bitcoin" }, { email: "manhvd15@gmail.com", trend: "Ethereum" }];
            await trendInterest.registerInterest(data[0].email, data[0].trend)
            await trendInterest.registerInterest(data[1].email, data[1].trend)

            const interests = await trendInterest.getInterestsByUser(owner);
            expect(interests[0].email).to.equal(data[0].email)
            expect(interests[0].trend).to.equal(data[0].trend)
            expect(interests[1].email).to.equal(data[1].email)
            expect(interests[1].trend).to.equal(data[1].trend)
        })

        it("Should owner clear interests", async () => {
            const { trendInterest, owner } = await deployTrendInterest();
            const data = [{ email: "manhvd1111@gmail.com", trend: "Bitcoin" }, { email: "manhvd2222@gmail.com", trend: "Ethereum" }];
            await trendInterest.registerInterest(data[0].email, data[0].trend)
            await trendInterest.registerInterest(data[1].email, data[1].trend)

            await trendInterest.connect(owner).clearAllLogical();


            const interest1 = trendInterest.interests(0);
            const interest2 = trendInterest.interests(1);
            expect(interest1).to.be.revertedWith("Error occurred: revert.");
            expect(interest2).to.be.revertedWith("Error occurred: revert.");
        })

        it("Should other account clear interests is revert", async () => {
            const { trendInterest, otherAccount } = await deployTrendInterest();
            const data = [{ email: "manhvd07@gmail.com", trend: "Bitcoin" }, { email: "manhvd15@gmail.com", trend: "Ethereum" }];
            await trendInterest.registerInterest(data[0].email, data[0].trend)
            await trendInterest.registerInterest(data[1].email, data[1].trend)

            const tx = trendInterest.connect(otherAccount).clearAllLogical();

            expect(tx).to.be.revertedWith("Error occurred: revert.")
        })

        it("Should email duplicate", async () => {
            const { trendInterest, owner } = await deployTrendInterest();
            const data = [{ email: "manhvd1507@gmail.com", trend: "Bitcoin" }, { email: "manhvd1507@gmail.com", trend: "Ethereum" }];
            await trendInterest.registerInterest(data[0].email, data[0].trend)
            const tx = trendInterest.registerInterest(data[1].email, data[1].trend)

            const interests = await trendInterest.getInterests(owner);
            expect(interests[0].email).to.equal(data[0].email)
            expect(interests[0].trend).to.equal(data[0].trend)

            await expect(tx).to.be.revertedWithCustomError(trendInterest, "EmailAlreadyRegistered")
        })
    })
})