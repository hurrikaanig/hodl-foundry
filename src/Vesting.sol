// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFHodl.sol";

contract Vesting is Ownable{

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastStakeTimestamp;
        uint256 claimedRewards;
        uint256 unlockTimestamp;
        uint256 vestingDurationIndex;
    }

    uint256 constant private ONE_YEAR = 365 days;
    uint256 constant private ONE_MONTH = 30 days;
    
    uint256[] public vestingDurations = [
        1 weeks,
        ONE_MONTH,
        6 * ONE_MONTH,
        ONE_YEAR,
        2 * ONE_YEAR
    ];
    uint256[] public tokenRatio = [
        1,
        6,
        50,
        238,
        1000
    ];
    uint256 public totalStakedTokens;
    uint256 TotalToCollect = 1000 ether;
    IFHodl public token;
    mapping(address => UserInfo) public stakers;

    constructor(IFHodl _token) {
        token = _token;
    }

    //
    // Vesting
    //

    function getStaker(address _user) external view returns (UserInfo memory) {
        return stakers[_user];
    }

    function vest(uint256 _amount, uint8 _durationIndex) public {
        if ( stakers[msg.sender].stakedAmount > 0) {
            require(_durationIndex >= stakers[msg.sender].vestingDurationIndex);
        }
        token.transferFrom(msg.sender, address(this), _amount);
        stakers[msg.sender].stakedAmount += _amount;
        stakers[msg.sender].lastStakeTimestamp = block.timestamp;
        stakers[msg.sender].unlockTimestamp = block.timestamp + vestingDurations[_durationIndex];
        totalStakedTokens += _amount;
    }

    function unvest() public {
        uint256 vestingTime = vestingDurations[stakers[msg.sender].vestingDurationIndex];
        require(stakers[msg.sender].stakedAmount > 0, "no balance to unvest");
        //add unstake penalty
        uint256 timeStaked = block.timestamp - stakers[msg.sender].lastStakeTimestamp;
        uint256 amountToCollect = 0;
        for (; timeStaked >= vestingTime; timeStaked -= vestingTime) {
            amountToCollect += 1;
        }
        uint256 percentage_of_tokens = stakers[msg.sender].stakedAmount * 10000 / totalStakedTokens * TotalToCollect;
        token.mint(amountToCollect * percentage_of_tokens / 10000, msg.sender);
        token.transferFrom(address(this), msg.sender, stakers[msg.sender].stakedAmount);
        totalStakedTokens -= stakers[msg.sender].stakedAmount;
        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].lastStakeTimestamp = 0;
    }

    function collectRewards() public {
        uint256 vestingTime = vestingDurations[stakers[msg.sender].vestingDurationIndex];
        require(block.timestamp - stakers[msg.sender].lastStakeTimestamp >= vestingTime);
        uint256 timeStaked = block.timestamp - stakers[msg.sender].lastStakeTimestamp;
        uint256 amountToCollect = 0;
        for (; timeStaked >= vestingTime; timeStaked -= vestingTime) {
            amountToCollect += 1;
        }
        uint256 percentage_of_tokens = stakers[msg.sender].stakedAmount * 10000 / totalStakedTokens * TotalToCollect;
        token.mint(amountToCollect * percentage_of_tokens / 10000, msg.sender);
        stakers[msg.sender].lastStakeTimestamp = block.timestamp;

    }

}