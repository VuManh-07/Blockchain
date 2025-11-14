/*
Tạo một hợp đồng thông minh hỗ trợ việc chuyển token đơn giản giữa hai blockchain khác nhau bằng phương pháp tiếp cận dựa trên event-based.
Hợp đồng nên phát ra một sự kiện khi việc chuyển token được bắt đầu,
sự kiện này có thể được một hợp đồng cầu nối trên một blockchain khác lắng nghe để hoàn tất việc chuyển token.
Hợp đồng thông minh nên bao gồm các chức năng để khởi tạo việc chuyển token và xác minh sự kiện.
Đảm bảo logic chuyển token triển khai các biện pháp bảo mật cơ bản chống lại các cuộc tấn công reentrancy.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SourceBridge {
    // simple counter-based nonce
    uint256 public globalNonce;

    event TransferInitiated(
        bytes32 indexed transferId,
        address indexed token,
        address indexed sender,
        uint256 srcChainId,
        uint dstChainId,
        address recipientOnDst,
        uint256 amount,
        uint256 timestamp
    );


    function initiateTransfer(
        address token,
        uint256 dstChainId,
        address recipientOnDst,
        uint256 amount
    ) external {
        require(amount > 0, "invalid amount");
        require(recipientOnDst != address(0), "invalid recipient");

        // Transfer tokens from user to this contract (lock)
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // create transferId
        bytes32 transferId = keccak256(
            abi.encodePacked(
                block.chainid,
                globalNonce,
                msg.sender,
                recipientOnDst,
                token,
                amount,
                block.timestamp
            )
        );
        globalNonce++;

        emit TransferInitiated(
            transferId,
            token,
            msg.sender,
            block.chainid,
            dstChainId,
            recipientOnDst,
            amount,
            block.timestamp
        );

    }

    // Admin function to release tokens back (e.g., when a return occurs)
}
