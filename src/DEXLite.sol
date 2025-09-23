// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract DEXLite is Ownable{
    
    IERC20  public tokenA;
    IERC20  public tokenB;

    struct Liquidator{
        bool permitted;
        uint256 tokenA;
        uint256 tokenB;
    }

    mapping(address => Liquidator) public liquidator;

    uint256 public reservesA;
    uint256 public reservesB;

    

    //custom Error
    error invalidAdddress();
    error onlyLiquidatorPermitted();

    //modifier
    modifier onlyLiquidator() {
        if(!liquidator[msg.sender].permitted) revert onlyLiquidatorPermitted();
    }

    constructor(IERC20 _tokenA, IERC20 _tokenB)
    Ownable(){
        if(_tokenA == address(0) || _tokenB == address(0)) revert invalidAddress();
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
}
