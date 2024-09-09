// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IDBALL.sol";

contract DBALL is IDBALL, ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    mapping(address => bool) whitelistedAddresses;

    function addWhitelistAddress(address _addressToWhitelist) external onlyRole(ADMIN_ROLE) {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelistedAddresses[_address];
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function mint(address to, uint256 amount) override external onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        // Mint + Burn + Whitelist address
        require(from == address(0) || to == address(0) || isWhitelisted(from) || isWhitelisted(to));
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal override {
        if (!isWhitelisted(spender)) {
            super._spendAllowance(owner, spender, amount);
        }
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}