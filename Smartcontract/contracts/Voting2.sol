/*
Tạo một hợp đồng bỏ phiếu đơn giản cho phép người dùng đề xuất và bỏ phiếu cho ứng cử viên.
Hợp đồng nên lưu trữ danh sách ứng cử viên, cho phép người dùng chỉ bỏ phiếu một lần và
theo dõi số phiếu bầu của từng ứng cử viên.
Ngoài ra, hãy triển khai chức năng truy xuất số phiếu bầu hiện tại của ứng cử viên và
xác định người chiến thắng sau khi bỏ phiếu hoàn tất.
Đảm bảo rằng chỉ chủ sở hữu hợp đồng mới có thể đề xuất ứng cử viên mới.
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Voting2 {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    mapping(address => bool) public hasVoted;
    address public owner;
    Candidate[] public candidates;

    uint256 public votingStart;
    uint256 public votingEnd;
    bool public votingActive;

    event EventProposeCandidate(
        string name,
        address creator,
        uint256 timestamp
    );
    event EventVote(string name, address voter);
    event EventVotingsStart(uint256 votingStart, uint256 votingEnd);
    event EventVotingEnded(uint256 votingEnd);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function startVote(uint256 durationSeconds) external {
        require(durationSeconds > 60, "time is very short"); // 1p
        require(votingActive, "Votings is no_active");
        require(candidates.length > 0, "No candidate");
        votingStart = block.timestamp + durationSeconds;

        votingStart = block.timestamp;
        votingEnd = block.timestamp + durationSeconds;
        votingActive = true;

        emit EventVotingsStart(votingStart, votingEnd);
    }

    function endVoting() external onlyOwner {
        require(votingActive, "Voting is not active");

        votingEnd = block.timestamp;
        votingActive = false;
        emit EventVotingEnded(votingEnd);
    }

    function proposeCandidate(string memory name) external onlyOwner {
        require(bytes(name).length > 0, "name is invalid");
        require(!votingActive, "actived");
        candidates.push(Candidate({name: name, voteCount: 0}));

        emit EventProposeCandidate(name, msg.sender, block.timestamp);
    }

    function vote(uint _candidateIndex) external {
        require(hasVoted[msg.sender] != true, "voted");
        require(votingActive, "vote is not active");
        require(votingEnd - block.timestamp > 0, "expire");

        candidates[_candidateIndex].voteCount += 1;
        hasVoted[msg.sender] = true;

        emit EventVote(candidates[_candidateIndex].name, msg.sender);
    }

    function getVotes(uint candidateIndex) external view returns (uint) {
        require(candidateIndex < candidates.length, "id is invalid");
        return candidates[candidateIndex].voteCount;
    }

    function getWinner() external view returns (string memory) {
        require(!votingActive, "voting is starting");
        require(votingEnd - block.timestamp < 0, "voting is starting");
        Candidate memory winner;

        for (uint256 i = 0; i <= candidates.length; i++) {
            if (candidates[i].voteCount > winner.voteCount) {
                winner = candidates[i];
            }
        }
        return winner.name;
    }
}
