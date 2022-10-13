// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFHodl.sol";

contract Vesting is Ownable{
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastStakeTimestamp;
        uint256 rewardDebt;
        uint256 vestingDurationIndex;
    }

    uint256 constant private ACC_PRECISION = 1e12;
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
    uint256 totalRatio; // sum of every tokenRatio
    uint256 lastRewardTimestamp; //
    uint256 accRewardPerShare;
    uint256 rewardPerSec;
    uint256 TotalToCollect = 1000 ether;
    IERC20 public token;
    
    mapping(address => UserInfo) public stakers;

    constructor(IERC20 _token) {
        token = _token;
    }

    //
    // Vesting
    //

    function getStaker(address _user) external view returns (UserInfo memory) {
        return stakers[_user];
    }

    function getUserRealStakedAmount(address _user) public view returns (uint256) {
        UserInfo storage user = stakers[_user];
        return user.stakedAmount / tokenRatio[user.vestingDurationIndex];
    }

    function updateRewards() public {
        if (block.timestamp <= lastRewardTimestamp) {
            return;
        }
        if(totalRatio == 0) {
            lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = block.timestamp - lastRewardTimestamp;
        uint256 rewardAmount = multiplier * rewardPerSec;
        accRewardPerShare = accRewardPerShare + rewardAmount * ACC_PRECISION;
        lastRewardTimestamp = block.timestamp;
    }

    function vest(uint256 _amount, uint8 _durationIndex) public {
        updateRewards();
        UserInfo storage user = stakers[msg.sender];
        if ( user.stakedAmount > 0) {
            require(_durationIndex >= user.vestingDurationIndex, "Can't stake with lower vesting time");
            collectRewards();
        }
        totalRatio = _amount * tokenRatio[_durationIndex];
        user.stakedAmount = (getUserRealStakedAmount(msg.sender) + _amount) * tokenRatio[_durationIndex];
        user.rewardDebt = user.stakedAmount * accRewardPerShare / ACC_PRECISION;
        user.vestingDurationIndex = _durationIndex;
        user.lastStakeTimestamp = block.timestamp;
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unvest(uint256 _amount) public {
        updateRewards();

        UserInfo storage user = stakers[msg.sender];
        require(getUserRealStakedAmount(msg.sender) >= _amount, "Not enough staked");
        require(block.timestamp >= user.lastStakeTimestamp + vestingDurations[user.vestingDurationIndex], "Tokens not unlocked yet");
        collectRewards();

        user.stakedAmount -= _amount * tokenRatio[user.vestingDurationIndex];
        user.rewardDebt = user.stakedAmount * accRewardPerShare / ACC_PRECISION;

        token.safeTransfer(msg.sender, _amount);
    }

    function collectRewards() private {
        UserInfo storage user = stakers[msg.sender];
        uint256 pending = user.stakedAmount * accRewardPerShare / ACC_PRECISION - user.rewardDebt;
        IFHodl(address(token)).mint(msg.sender, pending);
    }
}