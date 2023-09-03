// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "./IEarlyPack.sol";

contract EarlyAccess is AccessControlUpgradeable, PausableUpgradeable {
    // Consts
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // Storage
    IEarlyPack private _earlyPack;
    address payable private _beneficary;
    uint256 private _totalSupply;
    // @dev PackType => PackPrice
    mapping(uint256 => uint256) private _packPrices;

    function initialize(address earlyPack_, address payable beneficary_) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAWER_ROLE, _msgSender());

        _earlyPack = IEarlyPack(earlyPack_);
        _beneficary = beneficary_;
    }

    function setPackPrice(uint256 packType_, uint256 price_) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _packPrices[packType_] = price_;
    }

    function setBeneficary(address payable beneficary_) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _beneficary = beneficary_;
    }

    function purchasePack(uint256 packType_) public payable whenNotPaused {
        uint256 price = packPrice(packType_);
        require(price > 0, "Invalid pack");
        require(msg.value >= price, "Invalid Amount");

        (bool isSuccess, ) = _beneficary.call{value: msg.value}("");
        require(isSuccess, "Transfer failed");

        _earlyPack.safeMint(_msgSender(), _totalSupply, packType_);

        _totalSupply = _totalSupply + 1;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external virtual onlyRole(ADMIN_ROLE) whenNotPaused {
        _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external virtual onlyRole(ADMIN_ROLE) whenPaused {
        _unpause();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAll() public onlyRole(WITHDRAWER_ROLE) whenNotPaused {
        address payable to = payable(_msgSender());
        to.transfer(getBalance());
    }

    receive() external payable {}

    function packPrice(uint256 packType_) public view returns (uint256) {
        return _packPrices[packType_];
    }
}
