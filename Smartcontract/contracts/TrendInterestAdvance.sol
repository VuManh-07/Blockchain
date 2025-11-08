/*
Tạo một Hợp đồng Thông minh cho phép người dùng đăng ký sở thích của họ
về các xu hướng sắp tới trong Hợp đồng Thông minh.
Hợp đồng nên cho phép người dùng gửi địa chỉ email và xu hướng cụ thể mà họ quan tâm.
Triển khai một chức năng cho phép người dùng truy xuất tất cả các sở thích đã đăng ký 
và đảm bảo địa chỉ email được lưu trữ theo cách ngăn ngừa trùng lặp.
Ngoài ra, hãy bao gồm một chức năng để xóa tất cả các sở thích đã đăng ký,
chức năng này chỉ có thể được gọi bởi chủ sở hữu hợp đồng.
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TrendInterestAdvance {
    struct Interest {
        address user;
        string email;
        string trend;
        uint256 timestamp;
    }

    Interest[] public interests;

    mapping(bytes32 => uint) emailRegisteredInVersion;
    mapping(address => uint256[]) userInterestIds;

    address owner;
    uint64 version;

    event InterestRegisted(
        address user,
        string email,
        string trend,
        uint256 indexed id
    );
    event ClearAll(uint64 newVersion, address indexed by);

    error OnlyOwner();
    error EmailAlreadyRegistered();
    error EmptyEmailOrTrend();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }

        _;
    }

    constructor() {
        owner = msg.sender;
        version = 1;
    }

    function registerInterest(
        string calldata email,
        string calldata trend
    ) public {
        if (bytes(email).length == 0 || bytes(trend).length == 0)
            revert EmptyEmailOrTrend();

        bytes32 hashEmail = keccak256(bytes(email));

        if (emailRegisteredInVersion[hashEmail] == version)
            revert EmailAlreadyRegistered();

        uint256 id = interests.length;
        interests.push(
            Interest({
                user: msg.sender,
                email: email,
                trend: trend,
                timestamp: block.timestamp
            })
        );

        emailRegisteredInVersion[hashEmail] = version;
        userInterestIds[msg.sender].push(id);

        emit InterestRegisted(msg.sender, email, trend, id);
    }

    function getInterestsByUser(
        address user
    ) external view returns (Interest[] memory) {
        uint256[] storage ids = userInterestIds[user];
        Interest[] memory out = new Interest[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            out[i] = interests[ids[i]];
        }

        return out;
    }

    function getInterests() public view returns (Interest[] memory) {
        return interests;
    }

    function totalInterests() external view returns (uint256) {
        return interests.length;
    }

    function clearAllLogical() external onlyOwner {
        version += 1;
        emit ClearAll(version, msg.sender);
    }

    function clearAllHard() external onlyOwner {
        // WARNING: This may revert if the arrays are too large (gas limit).
        delete interests;

        // Clear user indices by iterating all users via a stored users list is necessary.
        // But since don't keep a full users list in this implementation,
        // cannot reliably clear userInterestIds mapping without extra bookkeeping.
        // Therefore recommend using clearAllLogical which is gas-efficient and safe.
        version += 1;
        emit ClearAll(version, msg.sender);
    }
}
