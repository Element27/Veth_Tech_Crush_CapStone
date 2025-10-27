// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VethToken.sol";

/**
 * @title VETH Token Test Suite
 * @dev Comprehensive tests for VETH token functionality
 * 
 * Run tests:
 * forge test
 * forge test -vv (verbose)
 * forge test --match-test testMint (specific test)
 */
contract VethTokenTest is Test {
    VETHToken public vethToken;
    
    address public owner;
    address public kinogho;
    address public jaybaby;
    address public dan;
    address public hamid;
    
    uint256 constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function setUp() public {
        owner = address(this);
        kinogho = address(0x1);
        jaybaby = address(0x2);
        dan = address(0x3);
        hamid = address(0x4);
        
        // Deploy VETH token
        vethToken = new VETHToken();
    }
    
    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testDeployment() public {
        assertEq(vethToken.name(), "Vote Ethereum");
        assertEq(vethToken.symbol(), "VETH");
        assertEq(vethToken.decimals(), 18);
        assertEq(vethToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(vethToken.balanceOf(owner), INITIAL_SUPPLY);
    }
    
    function testOwnerIsDeployer() public {
        assertEq(vethToken.owner(), owner);
    }
    
    /*//////////////////////////////////////////////////////////////
                        MINTING TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testMintByOwner() public {
        uint256 mintAmount = 1000 * 10**18;
        uint256 initialBalance = vethToken.balanceOf(kinogho);
        uint256 initialSupply = vethToken.totalSupply();
        
        vm.expectEmit(true, false, false, true);
        emit TokensMinted(kinogho, mintAmount);
        
        vethToken.mint(kinogho, mintAmount);
        
        assertEq(vethToken.balanceOf(kinogho), initialBalance + mintAmount);
        assertEq(vethToken.totalSupply(), initialSupply + mintAmount);
    }
    
    function testMintByNonOwnerFails() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.prank(kinogho);
        vm.expectRevert();
        vethToken.mint(jaybaby, mintAmount);
    }
    
    function testMintToZeroAddressFails() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.expectRevert("VETH: mint to zero address");
        vethToken.mint(address(0), mintAmount);
    }
    
    function testMintZeroAmountFails() public {
        vm.expectRevert("VETH: mint amount must be greater than 0");
        vethToken.mint(kinogho, 0);
    }
    
    function testBatchMint() public {
        address[] memory recipients = new address[](4);
        recipients[0] = kinogho;
        recipients[1] = jaybaby;
        recipients[2] = dan;
        recipients[3] = hamid;
        
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 100 * 10**18;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;
        amounts[3] = 400 * 10**18;
        
        vethToken.batchMint(recipients, amounts);
        
        assertEq(vethToken.balanceOf(kinogho), 100 * 10**18);
        assertEq(vethToken.balanceOf(jaybaby), 200 * 10**18);
        assertEq(vethToken.balanceOf(dan), 300 * 10**18);
        assertEq(vethToken.balanceOf(hamid), 400 * 10**18);
    }
    
    function testBatchMintArrayMismatchFails() public {
        address[] memory recipients = new address[](2);
        recipients[0] = kinogho;
        recipients[1] = jaybaby;
        
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**18;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;
        
        vm.expectRevert("VETH: arrays length mismatch");
        vethToken.batchMint(recipients, amounts);
    }
    
    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, kinogho, transferAmount);
        
        vethToken.transfer(kinogho, transferAmount);
        
        assertEq(vethToken.balanceOf(kinogho), transferAmount);
        assertEq(vethToken.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
    }
    
    function testTransferInsufficientBalanceFails() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.prank(kinogho);
        vm.expectRevert();
        vethToken.transfer(jaybaby, transferAmount);
    }
    
    function testTransferFrom() public {
        uint256 amount = 1000 * 10**18;
        
        // Owner approves kinogho to spend tokens
        vethToken.approve(kinogho, amount);
        
        // Kinogho transfers from owner to jaybaby
        vm.prank(kinogho);
        vethToken.transferFrom(owner, jaybaby, amount);
        
        assertEq(vethToken.balanceOf(jaybaby), amount);
        assertEq(vethToken.balanceOf(owner), INITIAL_SUPPLY - amount);
    }
    
    /*//////////////////////////////////////////////////////////////
                        BURNING TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testBurn() public {
        uint256 burnAmount = 1000 * 10**18;
        uint256 initialSupply = vethToken.totalSupply();
        uint256 initialBalance = vethToken.balanceOf(owner);
        
        vm.expectEmit(true, false, false, true);
        emit TokensBurned(owner, burnAmount);
        
        vethToken.burn(burnAmount);
        
        assertEq(vethToken.totalSupply(), initialSupply - burnAmount);
        assertEq(vethToken.balanceOf(owner), initialBalance - burnAmount);
    }
    
    function testBurnInsufficientBalanceFails() public {
        uint256 burnAmount = 1000 * 10**18;
        
        vm.prank(kinogho);
        vm.expectRevert();
        vethToken.burn(burnAmount);
    }
    
    function testBurnFrom() public {
        uint256 amount = 1000 * 10**18;
        
        // Transfer tokens to kinogho
        vethToken.transfer(kinogho, amount);
        
        // Kinogho approves jaybaby to burn tokens
        vm.prank(kinogho);
        vethToken.approve(jaybaby, amount);
        
        // Jaybaby burns from kinogho
        vm.prank(jaybaby);
        vethToken.burnFrom(kinogho, amount);
        
        assertEq(vethToken.balanceOf(kinogho), 0);
    }
    
    /*//////////////////////////////////////////////////////////////
                        APPROVAL TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testApprove() public {
        uint256 approvalAmount = 1000 * 10**18;
        
        vethToken.approve(kinogho, approvalAmount);
        
        assertEq(vethToken.allowance(owner, kinogho), approvalAmount);
    }
    
    function testIncreaseAllowance() public {
        uint256 initialAllowance = 1000 * 10**18;
        uint256 increaseAmount = 500 * 10**18;
        
        vethToken.approve(kinogho, initialAllowance);
        vethToken.increaseAllowance(kinogho, increaseAmount);
        
        assertEq(vethToken.allowance(owner, kinogho), initialAllowance + increaseAmount);
    }
    
    function testDecreaseAllowance() public {
        uint256 initialAllowance = 1000 * 10**18;
        uint256 decreaseAmount = 300 * 10**18;
        
        vethToken.approve(kinogho, initialAllowance);
        vethToken.decreaseAllowance(kinogho, decreaseAmount);
        
        assertEq(vethToken.allowance(owner, kinogho), initialAllowance - decreaseAmount);
    }
    
    /*//////////////////////////////////////////////////////////////
                        UTILITY FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testBalanceOfFormatted() public {
        uint256 amount = 1000 * 10**18;
        vethToken.transfer(kinogho, amount);
        
        assertEq(vethToken.balanceOfFormatted(kinogho), 1000);
    }
    
    function testTotalSupplyFormatted() public {
        assertEq(vethToken.totalSupplyFormatted(), 1_000_000);
    }
    
    /*//////////////////////////////////////////////////////////////
                        OWNERSHIP TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testTransferOwnership() public {
        vethToken.transferOwnership(kinogho);
        assertEq(vethToken.owner(), kinogho);
    }
    
    function testRenounceOwnership() public {
        vethToken.renounceOwnership();
        assertEq(vethToken.owner(), address(0));
    }
    
    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testFuzzMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0);
        vm.assume(amount < type(uint256).max - vethToken.totalSupply());
        
        uint256 initialSupply = vethToken.totalSupply();
        vethToken.mint(to, amount);
        
        assertEq(vethToken.balanceOf(to), amount);
        assertEq(vethToken.totalSupply(), initialSupply + amount);
    }
    
    function testFuzzTransfer(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0);
        vm.assume(amount <= vethToken.balanceOf(owner));
        
        vethToken.transfer(to, amount);
        assertEq(vethToken.balanceOf(to), amount);
    }
    
    function testFuzzBurn(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= vethToken.balanceOf(owner));
        
        uint256 initialSupply = vethToken.totalSupply();
        vethToken.burn(amount);
        
        assertEq(vethToken.totalSupply(), initialSupply - amount);
    }
}
