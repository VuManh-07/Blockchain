// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TargetBridge is ReentrancyGuard {
    using ECDSA for bytes32; // optional, we use static calls below

    address public admin;
    mapping(address => bool) public authorizedSigners;
    mapping(bytes32 => bool) public processed;
    mapping(address => address) public tokenMapping;

    event TransferCompleted(
        bytes32 indexed transferId,
        address indexed srcToken,
        address indexed dstToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 srcChainId,
        uint256 timestamp
    );
    event SignerUpdated(address signer, bool allowed);
    event TokenMappingUpdated(address srcToken, address dstToken);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), "zero admin");
        admin = _admin;
    }

    function setSigner(address signer, bool allowed) external onlyAdmin {
        authorizedSigners[signer] = allowed;
        emit SignerUpdated(signer, allowed);
    }

    function setTokenMapping(address srcToken, address dstToken) external onlyAdmin {
        tokenMapping[srcToken] = dstToken;
        emit TokenMappingUpdated(srcToken, dstToken);
    }

    /**
     * completeTransfer:
     * - transferId: unique id from source
     * - srcToken: address token on source chain
     * - sender: original sender on source chain
     * - recipient: recipient on this chain
     * - amount, srcChainId, timestamp: metadata
     * - signature: relayer signature of the hashed payload (signed via signMessage(arrayify(hash)) )
     */
    function completeTransfer(
        bytes32 transferId,
        address srcToken,
        address sender,
        address recipient,
        uint256 amount,
        uint256 srcChainId,
        uint256 timestamp,
        bytes calldata signature
    ) external nonReentrant {
        require(!processed[transferId], "already processed");
        require(recipient != address(0), "invalid recipient");
        require(amount > 0, "invalid amount");

        // recreate the message hash exactly as relayer signed it
        bytes32 message = keccak256(
            abi.encodePacked(transferId, srcToken, sender, recipient, amount, srcChainId, timestamp)
        );

        // build the Ethereum Signed Message hash (prefix + 32) — do it manually to avoid API mismatch
        bytes32 ethSigned = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));

        // recover signer
        address signer = ECDSA.recover(ethSigned, signature);
        require(authorizedSigners[signer], "invalid signer");

        // Mark processed BEFORE external interactions
        processed[transferId] = true;

        address dstToken = tokenMapping[srcToken];
        require(dstToken != address(0), "no dst token mapping");

        // Interact with ERC20 to transfer (assume bridge holds tokens or it's a wrapper with mint)
        IERC20(dstToken).transfer(recipient, amount);

        emit TransferCompleted(transferId, srcToken, dstToken, sender, recipient, amount, srcChainId, timestamp);
    }

    // emergency recovery (admin-only)
    function recoverERC20(address token, address to, uint256 amount) external onlyAdmin {
        IERC20(token).transfer(to, amount);
    }
}
