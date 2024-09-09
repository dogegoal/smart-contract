//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IDBALL.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BallCheckin is UUPSUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private constant BLOCK_TIME = 1; // in secs
    uint256 private constant DBALL_DECIMALS = 1000000;
    uint256 private constant DAY_TIME = 86400 / BLOCK_TIME;

    // Storage
    IDBALL private _dball;
    mapping(address => uint256) public lastClaimBlock;
    mapping(address => uint256) public milestoneProgess;
    uint256[] public milestones;
    uint256[] public milestoneRewards;
    uint256 public blockOffset;

    // Events
    event Checkin(address indexed sender, uint256 nextProgress, uint256 amount);

    function initialize(address dball_, uint256 blockOffset_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _dball = IDBALL(dball_);

        milestones = [
            0,
            600 / BLOCK_TIME, 
            1800 / BLOCK_TIME, 
            3600 / BLOCK_TIME, 
            7200 / BLOCK_TIME,
            14400 / BLOCK_TIME, 
            28800 / BLOCK_TIME
        ]; // in secs
        milestoneRewards = [
            5 * DBALL_DECIMALS, 
            10 * DBALL_DECIMALS, 
            30 * DBALL_DECIMALS, 
            60 * DBALL_DECIMALS, 
            120 * DBALL_DECIMALS, 
            240 * DBALL_DECIMALS,
            480 * DBALL_DECIMALS
        ]; // decimals = 6

        blockOffset = blockOffset_;
    }

    function checkin() external whenNotPaused {
        // update reset time if the day past
        address sender = _msgSender();
        (uint256 blocksUntilNextClaim, uint256 nextProgress) = nextMilestone(sender);
        require(blocksUntilNextClaim == 0, "not available");
        
        milestoneProgess[sender] = nextProgress;
        lastClaimBlock[sender] = block.number;
        uint256 reward = milestoneRewards[nextProgress];
        _dball.mint(sender, reward);

        emit Checkin(sender, nextProgress, reward);
    }

    // blocksUntilNextClaim - NextProgress
    function nextMilestone(address userAddr) public view returns(uint256, uint256) {
        uint256 _lastClaimBlock = lastClaimBlock[userAddr];
        if (_lastClaimBlock == 0) {
            // First claim
            return (0, 0);
        }

        // current progress is reset
        uint256 resetBlock = _resetBlock();
        if (resetBlock - DAY_TIME > _lastClaimBlock) {
            return (0, 0);
        }

        uint256 nextProgress = milestoneProgess[userAddr] + 1;
        // all rewards claimed
        if (nextProgress == milestones.length) {
            // return nextday
            return (resetBlock - block.number, 0);
        }

        // next progress
        uint256 nextClaimBlock = _lastClaimBlock + milestones[nextProgress];
        if (nextClaimBlock > block.number) {
            return (nextClaimBlock - block.number, nextProgress);
        }

        return (0, nextProgress);
    }

    function _resetBlock() internal view returns (uint256) {
        uint256 resetBlockAt = block.number - block.number % DAY_TIME + blockOffset;
        if (resetBlockAt < block.number) {
            return resetBlockAt + DAY_TIME;
        } else {
            return resetBlockAt;
        }
    }

    function setMilestones(
        uint256[] memory milestones_,
        uint256[] memory  milestoneRewards_
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(milestones_.length == milestoneRewards_.length, "invalid");
        milestones = milestones_;
        milestoneRewards = milestoneRewards_;
    }

    function setResetBlockOffset(
        uint256 blockOffset_
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(blockOffset_ < DAY_TIME, "invalid");
        blockOffset = blockOffset_;
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
