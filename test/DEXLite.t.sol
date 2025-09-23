// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DEXLite} from "../src/DEXLite.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
contract MockERC20 is ERC20{
    constructor(string memory name, string memory symbol) 
    ERC20(name, symbol){}

    function mint(address to, uint256 amount) public{
        _mint(to, amount);
    }
}

contract DEXLiteTest is Test {
    DEXLite public DEX;
    MockERC20 public mockTokenA;
    MockERC20 public mockTokenB;

    address public owner = makeAddr("owner");
    address public liquidator = makeAddr("liquidator");
    address public user = makeAddr("user");
    
    function setUp() public {
        mockTokenA = new MockERC20("tokenA", "TA");
        mockTokenB = new MockERC20("tokenB", "TB");

        DEX = new DEXLite(IERC20(address(mockTokenA)), IERC20(address(mockTokenB)), address(this));

        //mint token to liquidator
        mockTokenA.mint(liquidator, 1000 * 1e18);
        mockTokenB.mint(liquidator, 500 * 1e18);
    }

    function testAddLiquidity() public{
        vm.prank(liquidator);
        mockTokenA.approve(address(DEX), 100 * 1e18);
        vm.prank(liquidator);
         mockTokenB.approve(address(DEX), 50 * 1e18);
        vm.prank(liquidator);
        DEX.addLiquidity(100 * 1e18, 50 * 1e18);
        
        assertEq(DEX.reservesA(), 100 * 1e18);
        assertEq(DEX.reservesB(), 50 * 1e18);
        (bool permitted, uint256 tokenA, uint256 tokenB) = DEX.liquidator(liquidator);

        assertTrue(permitted);
        assertEq(tokenA, 100 * 1e18);
        assertEq(tokenB, 50 * 1e18);
    }
    function testRevertInvalidLiquidity() public {
        vm.prank(liquidator);
        mockTokenA.approve(address(DEX), 100 * 1e18);
        vm.prank(liquidator);
         mockTokenB.approve(address(DEX), 50 * 1e18);
        vm.prank(liquidator);
        vm.expectRevert(DEXLite.invalidLiquidity.selector);
        DEX.addLiquidity(0 , 50 * 1e18); 
    }
}
