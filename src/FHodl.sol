// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FHodl is ERC20, Ownable{

    uint256 maxSupply = 21000000 ether;

    constructor(uint _supply) ERC20("FHODL", "Forced Hodl") {
        require(_supply <= maxSupply);
        _mint(msg.sender, _supply);
    }

    function mint(uint256 _amount, address _to) external onlyOwner {        
        _mint(_to, _amount);
    }
}