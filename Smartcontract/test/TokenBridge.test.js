import { expect } from "chai";

describe("Cross-chain Bridge Simulation", function () {
    let deployer, user, relayer, recipient;
    let SourceBridge, TargetBridge, Token;

    beforeEach(async () => {
        [deployer, user, relayer, recipient] = await ethers.getSigners();

        // Deploy test ERC20 token
        const TokenFactory = await ethers.getContractFactory("TokenTest");
        Token = await TokenFactory.deploy(ethers.parseEther("1000000"));

        // Deploy SourceBridge (simulate Chain A)
        const SourceBridgeFactory = await ethers.getContractFactory("SourceBridge");
        SourceBridge = await SourceBridgeFactory.deploy();

        // Deploy TargetBridge (simulate Chain B)
        const TargetBridgeFactory = await ethers.getContractFactory("TargetBridge");
        TargetBridge = await TargetBridgeFactory.deploy(deployer.address);

        // Map token A → B
        await TargetBridge.setTokenMapping(Token.target, Token.target); // reuse same mock token for simplicity

        // Authorize relayer
        await TargetBridge.setSigner(relayer.address, true);
    });

    it("should emit event on source, relayer sign, and target complete transfer", async () => {
        await Token.connect(deployer).transfer(user.address, ethers.parseEther("200"));
        await Token.connect(deployer).transfer(TargetBridge.target, ethers.parseEther("100"));

        await Token.connect(user).approve(SourceBridge.target, ethers.parseEther("100"));

        const tx = await SourceBridge.connect(user).initiateTransfer(
            Token.target,
            31337, // fake target chainId
            recipient.address,
            ethers.parseEther("10")
        );
        const receipt = await tx.wait();

        const event = receipt.logs.find((log) => {
            const parsed = SourceBridge.interface.parseLog(log);
            return parsed?.name === "TransferInitiated";
        });

        const parsedEvent = SourceBridge.interface.parseLog(event);
        const [transferId, token, sender, srcChainId, dstChainId, recipientOnDst, amount, timestamp] = parsedEvent.args;
 
        const message = ethers.solidityPackedKeccak256(
            ["bytes32", "address", "address", "address", "uint256", "uint256", "uint256"],
            [transferId, token, sender, recipientOnDst, amount, srcChainId, timestamp]
        );
        const signature = await relayer.signMessage(ethers.getBytes(message));

        const completeTx = await TargetBridge.connect(deployer).completeTransfer(
            transferId,
            token,
            sender,
            recipientOnDst,
            amount,
            srcChainId,
            timestamp,
            signature
        );

        const completeReceipt = await completeTx.wait();
        let transferCompletedEvent;
        try {
            transferCompletedEvent = completeReceipt.logs
                .map(log => {
                    try {
                        return TargetBridge.interface.parseLog(log);
                    } catch {
                        return null;
                    }
                })
                .find(event => event && event.name === "TransferCompleted");
        } catch (e) {
            console.error("Error parsing logs:", e);
        }

        expect(transferCompletedEvent).to.not.be.undefined;
        expect(transferCompletedEvent.name).to.equal("TransferCompleted");



        await expect(
            TargetBridge.connect(deployer).completeTransfer(
                transferId,
                token,
                sender,
                recipientOnDst,
                amount,
                srcChainId,
                timestamp,
                signature
            )
        ).to.be.revertedWith("already processed");
    });
});
