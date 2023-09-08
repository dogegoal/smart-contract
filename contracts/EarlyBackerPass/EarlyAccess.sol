// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "./IEarlyPass.sol";

contract EarlyAccess is AccessControlUpgradeable, PausableUpgradeable {
    // Consts
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // Storage
    IEarlyPass private _earlyPass;
    address payable private _beneficary;
    uint256 private _totalSupply;
    // @dev PassType => PassPrice
    mapping(uint256 => uint256) private _passPrices;
    mapping(address => address) private _whitelists;

    // Event
    event Whitelisted(address indexed invitee, address indexed referrer);

    function initialize(address earlyPass_, address payable beneficary_) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAWER_ROLE, _msgSender());

        _earlyPass = IEarlyPass(earlyPass_);
        _beneficary = beneficary_;
    }

    function setPassPrice(uint256 passType_, uint256 price_) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _passPrices[passType_] = price_;
    }

    function setBeneficary(address payable beneficary_) public onlyRole(ADMIN_ROLE) whenNotPaused {
        _beneficary = beneficary_;
    }

    function purchasePass(uint256 passType_) public payable whenNotPaused {
        uint256 price = passPrice(passType_);
        require(price > 0, "Invalid pass");
        require(msg.value >= price, "Invalid Amount");

        (bool isSuccess, ) = _beneficary.call{value: msg.value}("");
        require(isSuccess, "Transfer failed");

        _earlyPass.safeMint(_msgSender(), _totalSupply, passType_);

        _totalSupply = _totalSupply + 1;
    }

    function finishWhitelist(address referrer_) external whenNotPaused {
        require(_whitelists[_msgSender()] == address(0), "Already whitelisted");
        address sender = _msgSender();
        _whitelists[sender] = referrer_;
        emit Whitelisted(sender, referrer_);
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

    function passPrice(uint256 passType_) public view returns (uint256) {
        return _passPrices[passType_];
    }
}
