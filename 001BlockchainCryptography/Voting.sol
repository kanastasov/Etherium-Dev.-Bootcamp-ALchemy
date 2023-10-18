// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Voting {
    enum VoteStates {Absent, Yes, No}
    uint constant VOTE_THRESHOLD = 10;

    struct Proposal {
        address target;
        bytes data;
        bool executed;
        uint yesCount;
        uint noCount;
        mapping (address => VoteStates) voteStates;
    }

    Proposal[] public proposals;

    event ProposalCreated(uint);
    event VoteCast(uint, address indexed);

    mapping(address => bool) members;

    constructor(address[] memory _members) {
        for(uint i = 0; i < _members.length; i++) {
            members[_members[i]] = true;
        }
        members[msg.sender] = true;
    }

    function newProposal(address _target, bytes calldata _data) external {
        require(members[msg.sender]);
        emit ProposalCreated(proposals.length);
        Proposal storage proposal = proposals.push();
        proposal.target = _target;
        proposal.data = _data;
    }

    function castVote(uint _proposalId, bool _supports) external {
        require(members[msg.sender]);
        Proposal storage proposal = proposals[_proposalId];

        // clear out previous vote
        if(proposal.voteStates[msg.sender] == VoteStates.Yes) {
            proposal.yesCount--;
        }
        if(proposal.voteStates[msg.sender] == VoteStates.No) {
            proposal.noCount--;
        }

        // add new vote
        if(_supports) {
            proposal.yesCount++;
        }
        else {
            proposal.noCount++;
        }

        // we're tracking whether or not someone has already voted
        // and we're keeping track as well of what they voted
        proposal.voteStates[msg.sender] = _supports ? VoteStates.Yes : VoteStates.No;

        emit VoteCast(_proposalId, msg.sender);

        if(proposal.yesCount == VOTE_THRESHOLD && !proposal.executed) {
            (bool success, ) = proposal.target.call(proposal.data);
            require(success);
        }
    }
}


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Voting.sol";

contract Target {
    address public sender;

    function mint() external {
        sender = msg.sender;
    }
}

contract VotingTest is Test {
    Voting public voting;
    Target public target;
    address[] members;

    function setUp() public {
        target = new Target();

        for(uint160 i = 2; i <= 11; i++) {
            members.push(address(i));
        }
        voting = new Voting(members);
        voting.newProposal(address(target), abi.encodeWithSignature("mint()"));
        
        for(uint160 i = 2; i <= 10; i++) {
            vm.prank(address(i));
            voting.castVote(0, true);
        }
    }

    function testStateBefore() public {
        assertEq(target.sender(), address(0), "the target should not have been called until 10 supporting votes");
    }

    function testStateAfter() public {
        vm.prank(address(11));
        voting.castVote(0, true);
        assertEq(target.sender(), address(voting), "the proposal should have been executed after 10 supporting votes");
    }
}
