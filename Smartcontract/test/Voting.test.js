const { expect } = require("chai")

describe("Voting", () => {
    const deployVoting = async () => {
        const [owner, otherAccount] = await ethers.getSigners();

        const Voting = await ethers.getContractFactory("Voting");
        const voting = await Voting.deploy();

        return { voting, owner, otherAccount }
    }

    describe("Deployment", () => {
        it("deployment", async () => {
            const { voting } = await deployVoting();

            expect(voting.target).to.not.eq(undefined);
        })
    })
})