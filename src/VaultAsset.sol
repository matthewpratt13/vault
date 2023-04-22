// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract VaultAsset is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol, _decimals) {}

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}
