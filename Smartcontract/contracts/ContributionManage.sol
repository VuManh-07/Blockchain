/*
Tạo một hợp đồng thông minh cho phép người dùng gửi Ether vào hợp đồng và sau đó rút tiền đóng góp của họ sau.
Hợp đồng nên triển khai một cơ chế để theo dõi tổng số Ether đã đóng góp.
Ngoài ra, người dùng nên được tính phí gas cho các giao dịch của họ, phí này cần được ghi lại trong một sự kiện.
Đảm bảo hợp đồng được thiết kế để tiết kiệm gas và cân nhắc tác động của phí gas đối với giao dịch của người dùng.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ContributionMange {
    uint256 public totalContributed;
    address public immutable owner;

    // reentrancy guard
    uint8 private _locked;

    mapping(address => uint) private _contributions;

    event ContributionMade(address indexed user, uint amount);
    event WithdrawalMade(address indexed user, uint amount);
    event GasFeeRecorded(
        address indexed user,
        uint256 gasUsed,
        uint gasPrice,
        uint256 feeInWei
    );

    error InsufficientBalance();
    error ReentrantCall();
    error ZeroAmount();

    constructor() {
        owner = msg.sender;
        totalContributed = 0;
        _locked = 1;
    }

    modifier nonReentGuard() {
        if (_locked == 0) revert ReentrantCall();
        _locked = 0;
        _;
        _locked = 1;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert();
        _;
    }

    function contribute() external payable {
        if (msg.value == 0) revert ZeroAmount();

        uint256 gasStart = gasleft();
        _contributions[msg.sender] += msg.value;
        totalContributed += msg.value;

        emit ContributionMade(msg.sender, msg.value);

        uint256 gasUsed = gasStart - gasleft();
        uint256 gp = tx.gasprice;
        uint256 fee = gasUsed * gp;

        emit GasFeeRecorded(msg.sender, gasUsed, gp, fee);
    }

    function withdraw(uint amount) external nonReentGuard {
        if (amount == 0) revert ZeroAmount();
        uint256 available = _contributions[msg.sender];
        if (amount > available) revert InsufficientBalance();

        uint256 gasStart = gasleft();

        _contributions[msg.sender] = available - amount;
        totalContributed -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit WithdrawalMade(msg.sender, amount);

        uint256 gasUsed = gasStart - gasleft();
        uint256 gp = tx.gasprice;
        uint256 fee = gasUsed * gp;
        emit GasFeeRecorded(msg.sender, gasUsed, gp, fee);
    }

    function contributionOf(address user) external view returns (uint256) {
        return _contributions[user];
    }
}
