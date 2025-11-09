/*
Tạo một hợp đồng bỏ phiếu đơn giản có thể tích hợp với một ứng dụng phi tập trung (DApp).
Hợp đồng này nên cho phép người dùng đề xuất và bỏ phiếu cho ứng viên.
Mỗi người dùng chỉ được bỏ phiếu một lần, và hợp đồng nên lưu trữ tổng số phiếu bầu cho mỗi ứng viên.
Triển khai một hàm để lấy thông tin ứng viên chiến thắng sau khi quá trình bỏ phiếu kết thúc.
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Voting {
    struct Candidate {
        string name;
        address proposer;
        uint256 voteCount;
    }

    address public owner;
    Candidate[] public candidates;

    uint256 public votingStart;
    uint256 public votingEnd;
    bool public votingActive;

    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public votedFor;

    event CandidateProposed(
        uint256 indexed id,
        string name,
        address indexed proposer
    );
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event VotingStarted(uint256 startTimestamp, uint256 endTimestamp);
    event VotingEnded(uint256 endTimestamp);

    error NotOwner();
    error EmptyName();
    error InvalidAddress();
    error VotingNotActive();
    error VotingAlreadyStarted();
    error VotingAlreadyEnded();
    error AlreadyVoted();
    error InvalidCandidate();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier duringVoting() {
        if (!votingActive) revert VotingNotActive();
        if (block.timestamp < votingStart || block.timestamp >= votingEnd)
            revert VotingNotActive();
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startVoting(uint256 durationSeconds) public onlyOwner {
        if(votingActive) revert VotingAlreadyStarted();
        require(candidates.length > 0, "No candidates");

        votingStart = block.timestamp;
        votingEnd = block.timestamp + durationSeconds;
        votingActive = true;

        emit VotingStarted(votingStart, votingEnd);
    }

    function endVoting() external onlyOwner {
        if(!votingActive) revert VotingNotActive();

        votingEnd = block.timestamp;
        votingActive = false;
        emit VotingEnded(votingEnd);
    }

    function proposeCandidate(string calldata name) external {
        if (bytes(name).length == 0) revert EmptyName();
        if (votingActive) revert VotingAlreadyStarted();

        candidates.push(
            Candidate({
                name: name,
                proposer: msg.sender,
                voteCount: 0
            })
        );

        emit CandidateProposed(
            candidates.length - 1,
            name,
            msg.sender
        );
    }

    function vote(uint256 _candidateId) public duringVoting {
        if(hasVoted[msg.sender] = true) revert AlreadyVoted();
        if(_candidateId >= candidates.length) revert InvalidCandidate();
        candidates[_candidateId].voteCount += 1;
        hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, _candidateId);
    }

    function getWinner() public view returns (string[] memory) {
        if(candidates.length == 0) {
            return new string[](0);
        }
        if(votingActive) revert VotingAlreadyStarted();
        
        uint256 maxvote = 0;
        for(uint256 i =0; i < candidates.length; i++) {
            if(candidates[i].voteCount > maxvote) {
                maxvote = candidates[i].voteCount;
            }
        }

        uint256 countwinners = 0;
        for(uint256 i =0; i < candidates.length; i++) {
            if(candidates[i].voteCount == maxvote) {
                countwinners++;
            }
        }

        string[] memory names = new string[](countwinners);
        uint idx=0;
        for(uint256 i =0; i < candidates.length; i++) {
            if(candidates[i].voteCount == maxvote) {
                names[idx] = candidates[i].name;
                idx++;
            }
        }

        return names;
    }
}