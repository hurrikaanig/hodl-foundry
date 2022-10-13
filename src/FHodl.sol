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

    function mint(address _to, uint256 _amount) external onlyOwner {        
        _mint(_to, _amount);
    }
}