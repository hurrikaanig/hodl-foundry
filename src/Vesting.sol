// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFHodl.sol";

contract Vesting is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 stakedAmount;
        uint256 lastStakeTimestamp;
        uint256 rewardDebt;
        uint256 vestingDurationIndex;
        address referral;
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
    uint256 referralRatio;
    uint256 TotalToCollect = 1000 ether;
    IERC20 public token;
    
    
    mapping(address => UserInfo) public stakers;

    constructor(IERC20 _token, uint256 _rewardPerSec, uint256 _referralRatio) {
        token = _token;
        rewardPerSec = _rewardPerSec;
        referralRatio = _referralRatio;
    }

    function _collectRewards() private {
        updateRewards();
        UserInfo storage user = stakers[msg.sender];
        uint256 pending = user.stakedAmount * accRewardPerShare / ACC_PRECISION - user.rewardDebt;
        user.rewardDebt += pending;
        if (user.referral != address(0)) {
            uint256 referralPending = pending * referralRatio / 10000;
            IFHodl(address(token)).mint(user.referral, referralPending);
        }
        IFHodl(address(token)).mint(msg.sender, pending);
    }

    function collectRewards() public nonReentrant {
        _collectRewards();
    }

    function getStaker(address _user) external view returns (UserInfo memory) {
        return stakers[_user];
    }

    function getUserRealStakedAmount(address _user) public view returns (uint256) {
        UserInfo storage user = stakers[_user];
        return user.stakedAmount / tokenRatio[user.vestingDurationIndex];
    }

    function pendingRewards(address _user) external view returns(uint256){
        UserInfo storage user = stakers[_user];
        return user.stakedAmount * accRewardPerShare / ACC_PRECISION - user.rewardDebt;
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
        accRewardPerShare = accRewardPerShare + rewardAmount * ACC_PRECISION / IFHodl(address(token)).balanceOf(address(this));
        lastRewardTimestamp = block.timestamp;
    }

    function vest(uint256 _amount, uint256 _durationIndex, address _referral) public nonReentrant {
        updateRewards();
        UserInfo storage user = stakers[msg.sender];
        if (user.referral == address(0)) {
            user.referral = _referral;
        }
        if ( user.stakedAmount > 0) {
            require(_durationIndex >= user.vestingDurationIndex, "Can't stake with lower vesting time");
            _collectRewards();
        }
        totalRatio = _amount * tokenRatio[_durationIndex];
        user.stakedAmount = (getUserRealStakedAmount(msg.sender) + _amount) * tokenRatio[_durationIndex];
        user.vestingDurationIndex = _durationIndex;
        user.lastStakeTimestamp = block.timestamp;
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unvest(uint256 _amount) public nonReentrant {
        updateRewards();

        UserInfo storage user = stakers[msg.sender];
        require(getUserRealStakedAmount(msg.sender) >= _amount, "Not enough staked");
        require(block.timestamp >= user.lastStakeTimestamp + vestingDurations[user.vestingDurationIndex], "Tokens not unlocked yet");
        _collectRewards();

        user.stakedAmount -= _amount * tokenRatio[user.vestingDurationIndex];
        user.rewardDebt = user.stakedAmount * accRewardPerShare / ACC_PRECISION;

        token.safeTransfer(msg.sender, _amount);
    }

    function setRewardPerSec(uint256 _rewardPerSec) external onlyOwner {
        rewardPerSec = _rewardPerSec;
    }

    function setReferralRatio(uint256 _referralRatio) external onlyOwner {
        require(_referralRatio <= 5000, "ratio too high");
        require(_referralRatio >= 0, "ratio too low");
        referralRatio = _referralRatio;
    }

    function setReferredRatio(uint256 _referredRatio) external onlyOwner {
        require(_referredRatio <= 2000, "ratio too high");
        require(_referredRatio >= 0, "ratio too low");
        referralRatio = _referredRatio;
    }
}