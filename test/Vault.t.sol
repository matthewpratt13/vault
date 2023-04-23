// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/VaultAsset.sol";

contract VaultTest is Test {
    VaultAsset public vast;
    Vault vault;

    function setUp() public {
        vast = new VaultAsset("vDai", "DAI", 18); // is ERC-20
        vault = new Vault(vast, "vAsset", "VAST");
    }

    function testFail_PauseAsNotOwner() public {
        vm.prank(address(0));
        vault.pauseVault();
    }

    function testFail_ActivateAsNotOwner() public {
        vm.prank(address(0));
        vault.activateVault();
    }
}
