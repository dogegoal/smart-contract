//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IDBALL.sol";
import "../Dogegoal/VerifySignature.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BallRewardHub is UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IDBALL private _dball;

    /// @dev
    /// Mapping Free nonce
    mapping(uint256 => bool) public claimed;
    address public referee;
    event ClaimBall(address indexed sender, uint256 nonce, uint256 amount);

    function initialize(address dball_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _dball = IDBALL(dball_);
    }

    function setReferee(address referee_) external onlyRole(ADMIN_ROLE) {
        referee = referee_;
    }

    function claim(
        uint256 nonce,
        uint256 amount,
        bytes memory signature
    ) external whenNotPaused {
        require(referee != address(0), "no referee");
        require(!claimed[nonce], "claimed");

        claimed[nonce] = true;

        // Verify signature
        address sender = _msgSender();
        bytes32 _messageHash = keccak256(abi.encodePacked(nonce, amount, sender));
        bool is_valid = VerifySignature.verify(referee, _messageHash, signature);
        if (!is_valid) {
            revert("invalid signature");
        }

        _dball.mint(sender, amount);

        emit ClaimBall(sender, nonce, amount);
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

    function _authorizeUpgrade(
        address
    ) internal override onlyRole(ADMIN_ROLE) {}
}
