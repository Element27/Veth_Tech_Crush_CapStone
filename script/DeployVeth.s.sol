// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VethToken.sol";

/**
 * @title Deploy VETH Token
 * @dev Foundry deployment script for VETH token
 * 
 * Usage:
 * forge script script/DeployVeth.s.sol:DeployVeth --rpc-url <RPC_URL> --broadcast --verify
 * 
 * Local deployment:
 * forge script script/DeployVeth.s.sol:DeployVeth --rpc-url http://localhost:8545 --broadcast
 */
contract DeployVeth is Script {
    
    function run() external returns (VETHToken) {
        // Get the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy VETH Token
        VETHToken vethToken = new VETHToken();
        
        console.log("VETH Token deployed at:", address(vethToken));
        console.log("Initial supply:", vethToken.totalSupply());
        console.log("Deployer balance:", vethToken.balanceOf(msg.sender));
        console.log("Token name:", vethToken.name());
        console.log("Token symbol:", vethToken.symbol());
        console.log("Decimals:", vethToken.decimals());
        
        // Stop broadcasting
        vm.stopBroadcast();
        
        return vethToken;
    }
}

/**
 * @title Deploy VETH Token with Custom Supply
 * @dev Alternative deployment with custom initial supply
 */
contract DeployVethCustom is Script {
    
    function run() external returns (VETHToken) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy VETH Token
        VETHToken vethToken = new VETHToken();
        
        // Optional: Mint additional tokens to specific addresses
        // Uncomment and modify as needed
        /*
        address recipient1 = 0x...; // Replace with actual address
        address recipient2 = 0x...; // Replace with actual address
        
        vethToken.mint(recipient1, 100_000 * 10**18);
        vethToken.mint(recipient2, 50_000 * 10**18);
        
        console.log("Minted to recipient1:", vethToken.balanceOf(recipient1));
        console.log("Minted to recipient2:", vethToken.balanceOf(recipient2));
        */
        
        console.log("VETH Token deployed at:", address(vethToken));
        console.log("Total supply:", vethToken.totalSupply());
        
        vm.stopBroadcast();
        
        return vethToken;
    }
}
