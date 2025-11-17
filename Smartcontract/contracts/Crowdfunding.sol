/*
Tạo một hợp đồng gây quỹ cộng đồng đơn giản cho phép người dùng đóng góp Ether cho một dự án.
Hợp đồng nên cho phép người tạo dự án đặt mục tiêu và thời hạn đóng góp.
Người dùng có thể đóng góp cho đến thời hạn, và nếu đạt được mục tiêu, người tạo dự án có thể rút tiền.
Nếu không đạt được mục tiêu trước thời hạn, người đóng góp có thể rút tiền.
Triển khai các sự kiện cho việc đóng góp và rút tiền.
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract Crowdfunding {
    struct Project {
        address payable creator;
        uint256 goal; // mục tiêu (wei)
        uint256 raised; // đã thu (wei)
        uint256 deadline; // hạn kết thức
        bool goalReached; // đã đạt mục tiêu chưa
        bool withdrawn; // creator đã rút tiền chưa
    }

    mapping(uint256 => Project) projects;
    mapping(uint256 => mapping(address => uint)) public contributes;
    uint256 public projectCount;

    // simple reentrancy guard
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private status = NOT_ENTERED;

    modifier nonReetrant() {
        require(status == NOT_ENTERED, "reetrant");
        status = ENTERED;
        _;
        status = NOT_ENTERED;
    }

    event ProjectCreated(
        uint256 indexed projectId,
        address indexed creator,
        uint256 goal,
        uint256 deadline
    );
    event Contributed(
        uint256 indexed projectId,
        address indexed contributor,
        uint256 amount
    );
    event CreatorWithdrawn(
        uint256 indexed projectId,
        address indexed creator,
        uint256 amount
    );
    event RefundIssued(
        uint256 indexed projectId,
        address indexed contributor,
        uint256 amount
    );

    function createProject(
        uint256 _goal,
        uint _duration
    ) external returns (uint256 projectId) {
        require(_goal > 0, "goal>0");
        require(_duration > 0, "duration>0");

        projectCount += 1;
        projectId = projectCount;

        projects[projectId] = Project({
            creator: payable(msg.sender),
            goal: _goal,
            raised: 0,
            deadline: block.timestamp + _duration,
            goalReached: false,
            withdrawn: false
        });

        emit ProjectCreated(
            projectId,
            msg.sender,
            _goal,
            block.timestamp + _duration
        );
    }

    function contribute(uint256 _projectId) public payable {
        Project storage p = projects[_projectId];
        require(p.creator != address(0), "project not exist");
        require(block.timestamp <= p.deadline, "deadline passed");

        require(msg.value > 0, "zero value");

        contributes[_projectId][msg.sender] += msg.value;
        p.raised += msg.value;

        if (!p.goalReached && p.raised >= p.goal) {
            p.goalReached = true;
        }

        emit Contributed(_projectId, msg.sender, msg.value);
    }

    function withdrawCreator(uint _projectId) external nonReetrant {
        Project storage p = projects[_projectId];
        require(p.creator != address(0), "project not exit");
        require(p.creator == msg.sender, "only creator");
        require(p.goalReached, "goal not reached");
        require(!p.withdrawn, "already withdraw");
        require(p.raised > 0, "no funds");

        uint256 amount = p.raised;
        p.withdrawn = true;
        p.raised = 0;

        (bool success, ) = p.creator.call{value: amount}("");

        require(success, "transfer failed");

        emit CreatorWithdrawn(_projectId, p.creator, amount);
    }

    function refund(uint256 _projectId) external nonReetrant {
        Project storage p = projects[_projectId];
        require(p.creator != address(0), "project not exist");
        require(p.deadline < block.timestamp, "deadline not yet passed");
        require(!p.goalReached, "project successed, no funds");

        uint256 contributed = contributes[_projectId][msg.sender];
        require(contributed > 0, "no contribute");

        contributes[_projectId][msg.sender] = 0;
        if (p.raised >= contributed) {
            p.raised -= contributed;
        } else {
            p.raised = 0;
        }

        (bool success, ) = msg.sender.call{value: contributed}("");

        require(success, "transfer failed");

        emit RefundIssued(_projectId, msg.sender, contributed);
    }

    function getContribution(
        uint256 _projectId,
        address _user
    ) external view returns (uint256) {
        return contributes[_projectId][_user];
    }

    function getProject(
        uint256 _projectId
    )
        external
        view
        returns (
            address creator,
            uint256 goal,
            uint256 raised,
            uint256 deadline,
            bool goalReached,
            bool withdrawn
        )
    {
        Project storage p = projects[_projectId];
        creator = p.creator;
        goal = p.goal;
        raised = p.raised;
        deadline = p.deadline;
        goalReached = p.goalReached;
        withdrawn = p.withdrawn;
    }
}
