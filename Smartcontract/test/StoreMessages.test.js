const { expect } = require("chai")

describe("StoreMessages", function () {
    const deployStoreMsg = async () => {
        const [owner, otherAccount] = await ethers.getSigners();

        const StoreMessages = await ethers.getContractFactory("StoreMessages");
        const storeMessages = await StoreMessages.deploy()

        return { storeMessages, owner, otherAccount }
    }

    describe("Deployment", function () {
        it("Nên triển khai thành công và có địa chỉ hợp lệ", async () => {
            const { storeMessages } = await deployStoreMsg();

            expect(storeMessages.target).to.not.equal(undefined)
        })

        it("Nên là owner set/get msg", async () => {
            const { storeMessages, owner } = await deployStoreMsg();
            const message = "Hello world!"

            await storeMessages.connect(owner).setMessage(message)

            expect(await storeMessages.connect(owner).getMessage()).to.equal(message);
        })

        it("Nên là Failed nếu khác owner", async () => {
            const { storeMessages, otherAccount } = await deployStoreMsg()
            const message = "Okay!"

            const tx1 = storeMessages.connect(otherAccount).setMessage(message);
            const tx2 = storeMessages.connect(otherAccount).getMessage(message);
            expect(tx1).to.be.revertedWith("Failed")
            expect(tx2).to.be.revertedWith("Failed")
        })
    })
})