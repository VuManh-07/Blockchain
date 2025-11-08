/* Tạo một hợp đồng Solidity có thể triển khai trên mạng Ethereum.
Hợp đồng này nên cho phép chủ sở hữu lưu trữ và cập nhật một chuỗi tin nhắn.
Hợp đồng nên triển khai một hàm để truy xuất tin nhắn.
Đảm bảo rằng chỉ chủ sở hữu mới có thể cập nhật tin nhắn. */

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract StoreMessages {
    string private message;
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function setMessage(string memory mes) public {
        require(msg.sender == owner, "Failed");
        message = mes;
    }

    function getMessage() public view returns (string memory) {
        require(msg.sender == owner, "Failed");
        return message;
    }
}

// property "view": chi ra la func nay chi duoc phep doc bien trong sc
