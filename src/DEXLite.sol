// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract DEXLite is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    struct Liquidator {
        bool permitted;
        uint256 tokenA;
        uint256 tokenB;
        uint256 PercentageShare;
    }

    mapping(address => Liquidator) public liquidator;

    uint256 public reservesA;
    uint256 public reservesB;
    uint256 public totalLiquidity;

    //custom Error
    error invalidAddress();
    error onlyLiquidatorPermitted();
    error invalidLiquidity();
    error invalidAmount();
    error TransferFailed();
    error insufficientBalance();
    error notEnoughShares();

    //events
    event LiqiudationAdded();
    event TokenSwapped();
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB);

    //modifier
    modifier onlyLiquidator() {
        if (!liquidator[msg.sender].permitted) revert onlyLiquidatorPermitted();
        _;
    }

    constructor(IERC20 _tokenA, IERC20 _tokenB, address _initialOwner) Ownable(_initialOwner) {
        if (address(_tokenA) == address(0) || address(_tokenB) == address(0)) revert invalidAddress();
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external {
        if (amountA == 0 || amountB == 0) revert invalidLiquidity();
        if (tokenA.balanceOf(msg.sender) < amountA || tokenB.balanceOf(msg.sender) < amountB) {
            revert insufficientBalance();
        }

        require(tokenA.transferFrom(msg.sender, address(this), amountA), "Tranfer Failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "Transfer Failed");

        uint256 userShare;

        if (reservesA == 0 && reservesB == 0) {
            userShare = 1e18;
        } else {
            uint256 liquidityAdded = Math.sqrt(amountA * amountB);
            totalLiquidity = Math.sqrt(reservesA * reservesB);
            userShare = liquidityAdded * 1e18 / (totalLiquidity + liquidityAdded);
        }

        reservesA += amountA;
        reservesB += amountB;

        liquidator[msg.sender].permitted = true;
        liquidator[msg.sender].tokenA += amountA;
        liquidator[msg.sender].tokenB += amountB;
        liquidator[msg.sender].PercentageShare += userShare;

        emit LiqiudationAdded();
    }

    function swapTokenAForTokenB(uint256 amountIn) external {
        if (amountIn == 0) revert invalidAmount();
        if (tokenA.balanceOf(msg.sender) < amountIn) revert insufficientBalance();

        require(tokenA.transferFrom(msg.sender, address(this), amountIn), "Transaction Failed");

        uint256 amountOut = (reservesB * amountIn) / (reservesA + amountIn);

        reservesA += amountIn;
        reservesB -= amountOut;

        bool success = tokenB.transfer(msg.sender, amountOut);
        if (!success) revert TransferFailed();

        emit TokenSwapped();
    }

    function swapTokenBForTokenA(uint256 amountIn) external {
        if (amountIn == 0) revert invalidAmount();
        if (tokenA.balanceOf(msg.sender) < amountIn) revert insufficientBalance();

        require(tokenB.transferFrom(msg.sender, address(this), amountIn), "Transaction Failed");

        uint256 amountOut = (reservesA * amountIn) / (reservesB + amountIn);

        reservesA -= amountOut;
        reservesB += amountIn;

        (bool success,) = msg.sender.call{value: amountOut}("");
        if (!success) revert TransferFailed();

        emit TokenSwapped();
    }

    function removeLiquidity(uint256 sharePercentage) external onlyLiquidator {
        if (sharePercentage == 0) revert invalidAmount();
        uint256 userShare = liquidator[msg.sender].PercentageShare;
        if (sharePercentage > userShare) revert notEnoughShares();

        uint256 amountA = (reservesA * sharePercentage) / 1e18;
        uint256 amountB = (reservesB * sharePercentage) / 1e18;

        reservesA -= amountA;
        reservesB -= amountB;

        liquidator[msg.sender].PercentageShare -= sharePercentage;
    
        if(liquidator[msg.sender].percentageShare == 0){
            liquidator[msg.sender].permitted = false;
            liquidator[msg.sender].tokenA = 0;
            liquidator[msg.sender].tokenB = 0;
        }

        require(tokenA.transfer(msg.sender, amountA), "Token A Transfer failed");
        require(tokenB.transfer(msg.sender, amountB), "Token B Transfer failed");

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }
}
