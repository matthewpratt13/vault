// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import {VaultAsset} from "../src/VaultAsset.sol";

contract VaultTest is Test {
    VaultAsset public _asset;
    Vault vault;

    function setUp() public {
        _asset = new VaultAsset("vDai", "DAI", 18); // is ERC-20
        vault = new Vault(_asset, "vAsset", "VAST");
    }

    // use `testFail` and not `test_RevertWhen` because of function simplicity
    function testFail_PauseAsNotOwner() public {
        vm.prank(address(0));
        vault.pauseVault();
    }

    // use `testFail` and not `test_RevertWhen` because of function simplicity
    function testFail_ActivateAsNotOwner() public {
        vm.prank(address(0));
        vault.activateVault();
    }

    function test_RevertIf_DepositWhenVaultPaused() public {
        vm.expectRevert(VaultInactive.selector);
        vm.prank(address(0));
        vault.deposit(1000, address(this));
    }

    function test_RevertIf_MintWhenVaultPaused() public {
        vm.expectRevert(VaultInactive.selector);
        vm.prank(address(0));
        vault.mint(1000, address(this));
    }

    function test_RevertIf_WithdrawWhenVaultPaused() public {
        vm.expectRevert(VaultInactive.selector);
        vm.prank(address(0));
        vault.withdraw(1000, address(this), msg.sender);
    }

    function test_RevertIf_RedeemWhenVaultPaused() public {
        vm.expectRevert(VaultInactive.selector);
        vm.prank(address(0));
        vault.redeem(1000, address(this), msg.sender);
    }
}
