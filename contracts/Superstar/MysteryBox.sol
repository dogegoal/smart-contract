//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IFootieSuperstar.sol";

contract MysteryBox is AccessControlUpgradeable, PausableUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
    bytes32 private constant RANDOMNESS_REPLIER = keccak256("RANDOMNESS_REPLIER");
    uint256 private constant RARITY_SUM = 100000;

    mapping(address => uint256) private lastBlockNumberCalled;
    /// @dev An mapping requestId to requester's address
    /// The user has to request the randomness for minting new NFT
    /// This will be used for VRF process on Dogegoal party
    mapping(uint256 => address) private _requesters;

    /// @dev An mapping rarity to meta size of players
    /// Should be editable by admin only
    mapping(uint8 => uint256) private _metaSizeByRarity;
    /// @dev An mapping rarity to rarity rate of superstar NFT
    /// sum of all rarity rate should be equal to RARITY_SUM
    /// Should be editable by admin only
    mapping(uint8 => uint256) private _rarityRate;

    IFootieSuperstar private _footieSuperstar;
    uint256 private _mintFee;

    // events to track onchain-offchain relationships.
    event RequestedRandomness(uint256 reqId, address invoker);
    event ReceivedRandomness(uint256 reqId, uint256 n);

    function initialize(address footieSuperstar_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _footieSuperstar = IFootieSuperstar(footieSuperstar_);
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

    function setFootieSuperstar(address footieSuperstar_) external onlyRole(ADMIN_ROLE) {
        _footieSuperstar = IFootieSuperstar(footieSuperstar_);
    }

    function setMintFee(uint256 fee) external onlyRole(ADMIN_ROLE) {
        _mintFee = fee;
    }

    function mintFee() public view returns (uint256) {
        return _mintFee;
    }

    function openBox() external payable whenNotPaused onlyNonContract oncePerBlock(_msgSender()) returns (uint256) {
        require(_mintFee > 0 && msg.value >= _mintFee, "not enough money");
        uint256 requestId = uint256(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    tx.origin,
                    tx.origin.balance,
                    block.timestamp,
                    blockhash(block.number - 1),
                    block.gaslimit,
                    gasleft()
                )
            )
        );
        _requesters[requestId] = _msgSender();
        emit RequestedRandomness(requestId, _msgSender());

        return requestId;
    }

    function randoml2(uint256 randomness_, uint256 max_) internal view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, randomness_))) %
            max_;
    }

    function fulfillRandomness(
        uint256 requestId,
        uint256 randomness
    ) external whenNotPaused onlyRole(RANDOMNESS_REPLIER) {
        address requester = _requesters[requestId];
        uint256 rarityRate = randoml2(randomness, RARITY_SUM);

        uint8 rarityIndex = 1;
        for (rarityIndex = 2; rarityIndex <= 4; rarityIndex++) {
            if (_rarityRate[rarityIndex] > rarityRate) {
                break;
            }
            rarityRate = rarityRate - _rarityRate[rarityIndex];
        }

        uint256 metaId = randoml2(randomness, _metaSizeByRarity[rarityIndex]) + 1;

        _footieSuperstar.safeMint(requester, rarityIndex, metaId);
        emit ReceivedRandomness(requestId, randomness);
    }

    function withdrawAll(address addr) external onlyRole(WITHDRAWER) {
        address payable _to = payable(addr);
        _to.transfer(address(this).balance);
    }

    function withdraw(address addr, uint256 amount) external onlyRole(WITHDRAWER) {
        uint256 balance = address(this).balance;
        require(amount <= balance, "invalid amount");
        address payable _to = payable(addr);
        _to.transfer(amount);
    }

    //////////////
    /// Modifiers
    //////////////
    modifier onlyNonContract() {
        _onlyNonContract();
        _;
    }

    function _onlyNonContract() internal view {
        require(tx.origin == _msgSender(), "only non contract");
    }

    modifier oncePerBlock(address user) {
        _oncePerBlock(user);
        _;
    }

    function _oncePerBlock(address user) internal {
        require(lastBlockNumberCalled[user] < block.number, "one per block");
        lastBlockNumberCalled[user] = block.number;
    }
}
