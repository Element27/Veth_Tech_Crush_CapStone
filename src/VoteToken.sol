// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract VoteToken is ERC20, ERC20Snapshot, Ownable, Pausable, ReentrancyGuard {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 snapshotId;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 quorum;
    }

    uint256 public proposalCount;
    uint256 public minVotingPeriod = 1 days;
    uint256 public maxVotingPeriod = 30 days;
    uint256 public proposalCreationCooldown = 1 minutes;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public lastProposalTimestamp;

    event ProposalCreated(uint256 id, address proposer, uint256 snapshotId, uint256 startTime, uint256 endTime, uint256 quorum, string description);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 proposalId, bool success);

    error InvalidVotingPeriod();
    error VotingNotActive();
    error AlreadyVoted();
    error ProposalExecutedAlready();
    error QuorumNotReached();
    error VotePeriodTooSoon();

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _jaybaby,
        address _dan
    ) ERC20(_name, _symbol) {
        uint256 half = _initialSupply / 2;

        if (_jaybaby != address(0)) {
            _mint(_jaybaby, half);
        } else {
            _mint(msg.sender, half);
        }

        if (_dan != address(0)) {
            _mint(_dan, _initialSupply - half);
        } else {
            _mint(msg.sender, _initialSupply - half);
        }

        transferOwnership(msg.sender);
    }

    // ---------------- Token Admin ----------------

    function snapshot() external onlyOwner whenNotPaused returns (uint256) {
        return _snapshot();
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner whenNotPaused {
        _burn(from, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ---------------- Governance ----------------

    function createProposal(
        string calldata description,
        uint256 votingPeriodSeconds,
        uint256 quorumWeight
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (votingPeriodSeconds < minVotingPeriod || votingPeriodSeconds > maxVotingPeriod)
            revert InvalidVotingPeriod();

        if (block.timestamp < lastProposalTimestamp[msg.sender] + proposalCreationCooldown)
            revert VotePeriodTooSoon();

        uint256 snap = _snapshot();
        uint256 start = block.timestamp;
        uint256 end = block.timestamp + votingPeriodSeconds;

        proposalCount += 1;
        uint256 pid = proposalCount;

        proposals[pid] = Proposal({
            id: pid,
            proposer: msg.sender,
            description: description,
            snapshotId: snap,
            startTime: start,
            endTime: end,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            quorum: quorumWeight
        });

        lastProposalTimestamp[msg.sender] = block.timestamp;

        emit ProposalCreated(pid, msg.sender, snap, start, end, quorumWeight, description);
        return pid;
    }

    function vote(uint256 proposalId, bool support) external whenNotPaused nonReentrant {
        Proposal storage p = proposals[proposalId];

        if (p.id == 0) revert VotingNotActive();
        if (block.timestamp < p.startTime || block.timestamp > p.endTime) revert VotingNotActive();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        uint256 weight = balanceOfAt(msg.sender, p.snapshotId);
        require(weight > 0, "no voting weight");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    function executeProposal(uint256 proposalId) external whenNotPaused nonReentrant returns (bool) {
        Proposal storage p = proposals[proposalId];

        if (p.id == 0) revert VotingNotActive();
        if (block.timestamp <= p.endTime) revert VotingNotActive();
        if (p.executed) revert ProposalExecutedAlready();

        uint256 totalVoted = p.forVotes + p.againstVotes;
        if (totalVoted < p.quorum) revert QuorumNotReached();

        p.executed = true;
        bool success = p.forVotes > p.againstVotes;

        emit ProposalExecuted(proposalId, success);
        return success;
    }

    // ---------------- Admin Config ----------------

    function setMinVotingPeriod(uint256 secs) external onlyOwner {
        require(secs >= 1 hours, "too small");
        minVotingPeriod = secs;
    }

    function setMaxVotingPeriod(uint256 secs) external onlyOwner {
        require(secs <= 90 days, "too large");
        maxVotingPeriod = secs;
    }

    function setProposalCreationCooldown(uint256 secs) external onlyOwner {
        proposalCreationCooldown = secs;
    }

    // ---------------- Overrides ----------------

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getVotesAt(address account, uint256 snapshotId) external view returns (uint256) {
        return balanceOfAt(account, snapshotId);
    }

    // ---------------- Rescue ----------------

    function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "cannot rescue this token");
        IERC20(tokenAddress).transfer(to, amount);
    }
}
