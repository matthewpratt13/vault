// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VaultAsset is ERC20, Ownable {
    uint256 public _totalSupply = 1_000_000;

    constructor() ERC20("vAsset", "VAST", 18) {
        _mint(address(0), _totalSupply);
    }

    function burn(uint256 value) public onlyOwner {
        _burn(msg.sender, value);
    }
}
