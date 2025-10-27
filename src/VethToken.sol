// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VETH Token
 * @dev ERC-20 token for token-gated voting system
 * @notice Class Project - Token-Gated Voting System
 * @author Kinogho, Jaybaby, Dan
 * 
 * Features:
 * - Mintable by owner
 * - Burnable by token holders
 * - Fixed decimals (18)
 * - Initial supply minted to deployer
 */
contract VETHToken is ERC20, ERC20Burnable, Ownable {
    
    // Token decimals (standard is 18)
    uint8 private constant _decimals = 18;
    
    // Initial supply: 1,000,000 VETH tokens
    uint256 private constant INITIAL_SUPPLY = 1_000_000 * 10**_decimals;
    
    // Team members for this class project
    string[] private _teamMembers;
    
    // Project information
    string public constant PROJECT_NAME = "Token-Gated Voting System";
    string public constant PROJECT_TYPE = "Capstone Project";
    
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    
    /**
     * @dev Constructor that mints initial supply to deployer
     */
    constructor() ERC20("Vote Ethereum", "VETH") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
        
        // Initialize team members
        _teamMembers.push("Kinogho");
        _teamMembers.push("Jaybaby");
        _teamMembers.push("Dan");
    }
    
    /**
     * @dev Returns all team members who built this contract
     */
    function getTeamMembers() public view returns (string[] memory) {
        return _teamMembers;
    }
    
    /**
     * @dev Returns project information
     */
    function getProjectInfo() public pure returns (string memory name, string memory projectType) {
        return (PROJECT_NAME, PROJECT_TYPE);
    }
    
    /**
     * @dev Mints new tokens (only owner can call)
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint (in wei)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "VETH: mint to zero address");
        require(amount > 0, "VETH: mint amount must be greater than 0");
        
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    /**
     * @dev Batch mint tokens to multiple addresses
     * @param recipients Array of addresses to receive tokens
     * @param amounts Array of amounts corresponding to each recipient
     */
    function batchMint(address[] calldata recipients, uint256[] calldata amounts) 
        external 
        onlyOwner 
    {
        require(recipients.length == amounts.length, "VETH: arrays length mismatch");
        require(recipients.length > 0, "VETH: empty arrays");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "VETH: mint to zero address");
            require(amounts[i] > 0, "VETH: mint amount must be greater than 0");
            
            _mint(recipients[i], amounts[i]);
            emit TokensMinted(recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev Burns tokens from caller's balance
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public override {
        super.burn(amount);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Burns tokens from specified account (requires approval)
     * @param account Account to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) public override {
        super.burnFrom(account, amount);
        emit TokensBurned(account, amount);
    }
    
    /**
     * @dev Returns the number of decimals used for token amounts
     */
    function decimals() public pure override returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Returns token balance in human-readable format (with decimals)
     * @param account Address to check balance
     */
    function balanceOfFormatted(address account) public view returns (uint256) {
        return balanceOf(account) / 10**_decimals;
    }
    
    /**
     * @dev Emergency function to recover accidentally sent ERC20 tokens
     * @param tokenAddress Address of the ERC20 token to recover
     * @param amount Amount of tokens to recover
     */
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "VETH: cannot recover VETH tokens");
        IERC20(tokenAddress).transfer(owner(), amount);
    }
    
    /**
     * @dev Returns total supply in human-readable format
     */
    function totalSupplyFormatted() public view returns (uint256) {
        return totalSupply() / 10**_decimals;
    }
}
