// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/VoteToken.sol";

contract DeployVoteToken is Script {
    function run() external {
        // Replace these with your team members’ wallet addresses
        address jaybaby = 0x1111111111111111111111111111111111111111;
        address dan = 0x2222222222222222222222222222222222222222;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        VoteToken voteToken = new VoteToken(
            "VoteToken",
            "VOTE",
            1_000_000 ether,   // total supply
            jaybaby,
            dan
        );

        console2.log("VoteToken deployed at:", address(voteToken));

        vm.stopBroadcast();
    }
}