// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "solmate/tokens/ERC20.sol";
import "solmate/mixins/ERC4626.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

error VaultInactive();
error Unauthorized();

contract Vault is ERC4626, Ownable2Step {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    ERC20 public immutable asset_;
    bool public vaultPaused;

    constructor(ERC20 _asset, string memory _name, string memory _symbol) ERC4626(_asset, _name, _symbol) {
        asset_ = _asset;
        vaultPaused = true;
    }

    modifier vaultActive() {
        if (vaultPaused) {
            revert VaultInactive();
        }
        _;
    }

    function pauseVault() external onlyOwner {
        vaultPaused = true;
    }

    function activateVault() external onlyOwner {
        vaultPaused = false;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual override vaultActive returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset_.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual override vaultActive returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset_.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override
        vaultActive
        returns (uint256 shares)
    {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset_.safeTransfer(receiver, assets);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        vaultActive
        returns (uint256 assets)
    {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset_.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual override vaultActive returns (uint256) {
        return asset_.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view virtual override vaultActive returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual override vaultActive returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual override vaultActive returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual override vaultActive returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual override vaultActive returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual override vaultActive returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual override vaultActive returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual override vaultActive returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual override vaultActive returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual override vaultActive returns (uint256) {
        return balanceOf[owner];
    }
}
