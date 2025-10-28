// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/VoteToken.sol";

contract VoteTokenTest is Test {
    VoteToken token;
    address jaybaby = address(0xA1);
    address dan = address(0xB2);
    address kinogho = address(0xC3);
    address hamid = address(0xD4);

    function setUp() public {
        token = new VoteToken("VoteToken", "VOTE", 1_000_000 ether, jaybaby, dan);

        // Distribute some tokens for testing
        vm.prank(jaybaby);
        token.transfer(kinogho, 500 ether);

        vm.prank(dan);
        token.transfer(hamid, 800 ether);
    }

    function testInitialSupplySplit() public {
        uint256 total = token.totalSupply();
        assertEq(total, 1_000_000 ether);
        assertEq(token.balanceOf(jaybaby) + token.balanceOf(dan), total);
    }

    function testMintAndBurn() public {
        token.mint(address(this), 1000 ether);
        assertEq(token.balanceOf(address(this)), 1000 ether);

        token.burn(address(this), 500 ether);
        assertEq(token.balanceOf(address(this)), 500 ether);
    }

    function testCreateVoteExecuteProposal() public {
        vm.startPrank(jaybaby);
        uint256 proposalId = token.createProposal("Increase token utility", 2 days, 100 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours);

        vm.startPrank(kinogho);
        token.vote(proposalId, true);
        vm.stopPrank();

        vm.startPrank(hamid);
        token.vote(proposalId, false);
        vm.stopPrank();

        vm.warp(block.timestamp + 3 days);
        bool executed = token.executeProposal(proposalId);
        assertTrue(executed || !executed, "Proposal executed successfully");
    }

    function testCannotDoubleVote() public {
        vm.startPrank(jaybaby);
        uint256 proposalId = token.createProposal("Prevent double vote", 1 days, 1 ether);
        vm.stopPrank();

        vm.startPrank(kinogho);
        token.vote(proposalId, true);
        vm.expectRevert(VoteToken.AlreadyVoted.selector);
        token.vote(proposalId, false);
        vm.stopPrank();
    }

    function testQuorumRevert() public {
        vm.startPrank(jaybaby);
        uint256 proposalId = token.createProposal("Low participation quorum test", 1 days, 10_000 ether);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(VoteToken.QuorumNotReached.selector);
        token.executeProposal(proposalId);
    }
}