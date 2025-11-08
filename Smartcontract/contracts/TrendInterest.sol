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

contract TrendInterest {
    struct Interest {
        address user;
        string email;
        string trend;
    }

    Interest[] public interests;
    mapping(string => bool) emails;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function RegisterInterest(
        string calldata email,
        string calldata trend
    ) public {
        require(bytes(email).length > 0, "Email empty");
        require(bytes(trend).length > 0, "Trend is empty");
        require(emails[email] == false, "Email duplicate");

        interests.push(
            Interest({user: msg.sender, email: email, trend: trend})
        );

        emails[email] = true;
    }

    function getInterests() public view returns (Interest[] memory) {
        return interests;
    }

    function clearInterests() public onlyOwner {
        delete interests;
    }
}
