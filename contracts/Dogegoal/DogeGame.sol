//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./VerifySignature.sol";
import "../Superstar/IFootieSuperstar.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract DogeGame is AccessControlUpgradeable, PausableUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER = keccak256("WITHDRAWER");
    bytes32 private constant TOURNAMENT_CREATOR = keccak256("TOURNAMENT_CREATOR");

    // Structs
    enum PARTICIPANT_STATE {
        NOT_JOIN,
        JOINED,
        CLAIMED
    }

    struct Tournament {
        uint16 currentSlots;
        uint16 slots;
        uint256 entryFee;
        uint256 totalReward;
    }

    // Storage
    uint256 private _energyFee;
    mapping(uint256 => Tournament) tournaments;
    mapping(uint256 => mapping(address => PARTICIPANT_STATE)) participants;
    mapping(address => uint256) private lastBlockNumberCalled;
    address _referee;
    IFootieSuperstar private _footieSuperstar;
    mapping(uint256 => address) tournamentToken;
    mapping(address => bool) whitelistedToken;

    // Events
    event EnergyBought(address sender);
    event TournamentCreated(uint16 slots, address host, uint256 tournamentId, uint256 entry_fee, string name);
    event Erc20TournamentCreated(uint256 tournamentId, address token);
    event PvpMatch(address challenger, address opponent, uint256 leagueId);
    event TournamentRegistered(address register, uint256 tournamentId);
    event TournamentRewardClaimed(uint16 rank, address winner, uint256 tournamentId, uint256 reward);
    event TournamentFunded(address who, uint256 tournamentId, uint256 fundValue);
    event Received(address who, uint256 amount);

    function initialize(address footieSuperstar_) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _footieSuperstar = IFootieSuperstar(footieSuperstar_);
    }

    function buyEnergy() external payable whenNotPaused {
        require(_energyFee > 0 && msg.value >= _energyFee, "not enough money");
        emit EnergyBought(_msgSender());
    }

    function startPvpMatch(
        address opponent,
        uint256 leagueId
    ) external onlyNonContract oncePerBlock(_msgSender()) whenNotPaused {
        address sender = _msgSender();
        // Light check if this user has at least 3 superstar NFTs
        require(_footieSuperstar.balanceOf(sender) >= 3, "not enough players");
        emit PvpMatch(sender, opponent, leagueId);
    }

    function startPvpMatchV2(
        address opponent,
        uint256 leagueId
    ) external onlyNonContract oncePerBlock(_msgSender()) whenNotPaused {
        address sender = _msgSender();
        emit PvpMatch(sender, opponent, leagueId);
    }

    // Tournament
    function getTournament(
        uint256 tournamentId
    ) public view returns (uint16 currentSlots, uint16 slots, uint256 entryFee, uint256 totalReward) {
        Tournament memory tournament = tournaments[tournamentId];
        currentSlots = tournament.currentSlots;
        slots = tournament.slots;
        entryFee = tournament.entryFee;
        totalReward = tournament.totalReward;
    }

    function getTournamentRewards(uint256 tournamentId) public view returns (uint256[4] memory rewards) {
        Tournament memory tournament = tournaments[tournamentId];
        uint256 totalReward = tournament.totalReward;
        uint256 first = (totalReward * 475) / 1000;
        uint256 second = (totalReward * 250) / 1000;
        uint256 third = (totalReward * 125) / 1000;
        rewards = [first, second, third, third];
    }

    /**
     * @dev called by TOURNAMENT_CREATOR only
     */
    function createTournament(
        uint16 slots_,
        string memory name,
        uint256 entry_fee_
    ) external whenNotPaused onlyRole(TOURNAMENT_CREATOR) {
        require(slots_ > 2 && (slots_ & (slots_ - 1) == 0), "invalid slot");

        _createTournament(slots_, name, entry_fee_);
    }

    /**
     * @dev called by ADMIN_ROLE only
     * allow token to be used in knockout tournament
     */
    function whitelistToken(address token) external onlyRole(ADMIN_ROLE) {
        whitelistedToken[token] = true;
    }

    /**
     * @dev called by ADMIN_ROLE only
     * prevent token to be used in knockout tournament
     */
    function blacklistToken(address token) external onlyRole(ADMIN_ROLE) {
        whitelistedToken[token] = false;
    }

    function isWhitelisted(address token) public view returns (bool) {
        return whitelistedToken[token];
    }

    /**
     * @dev called by TOURNAMENT_CREATOR only
     */
    function createErc20Tournament(
        address token,
        uint16 slots_,
        string memory name,
        uint256 entry_fee_
    ) external whenNotPaused onlyRole(TOURNAMENT_CREATOR) {
        require(slots_ > 2 && (slots_ & (slots_ - 1) == 0), "invalid slot");
        require(isWhitelisted(token), "token not whitelisted");
        uint256 tournamentId = _createTournament(slots_, name, entry_fee_);

        tournamentToken[tournamentId] = token;
        emit Erc20TournamentCreated(tournamentId, token);
    }

    function _createTournament(uint16 slots_, string memory name, uint256 entry_fee_) internal returns (uint256) {
        uint256 tournamentId = uint256(
            keccak256(
                abi.encodePacked(
                    name,
                    entry_fee_,
                    slots_,
                    tx.origin,
                    tx.origin.balance,
                    block.timestamp,
                    blockhash(block.number - 1),
                    block.gaslimit,
                    gasleft()
                )
            )
        );

        tournaments[tournamentId] = Tournament(0, slots_, entry_fee_, entry_fee_ * slots_);

        emit TournamentCreated(slots_, _msgSender(), tournamentId, entry_fee_, name);
        return tournamentId;
    }

    /**
     * @dev called by anyone
     */
    function fundTournament(uint256 tournamentId) external payable whenNotPaused {
        Tournament storage tournament = tournaments[tournamentId];
        require(tournament.slots > 0, "no tournament");
        uint256 fundValue = msg.value;
        require(fundValue > 0, "invalid money");
        address sender = _msgSender();
        require(tournament.currentSlots < tournament.slots, "full slots");
        address tokenAddress = tournamentToken[tournamentId];
        require(tokenAddress == address(0x0), "erc20 tournament");

        tournament.totalReward = tournament.totalReward + fundValue;

        emit TournamentFunded(sender, tournamentId, fundValue);
    }

    function fundErc20Tournament(uint256 tournamentId, uint256 fundValue) external whenNotPaused {
        Tournament storage tournament = tournaments[tournamentId];
        require(tournament.slots > 0, "no tournament");
        require(fundValue > 0, "invalid money");
        address sender = _msgSender();
        require(tournament.currentSlots < tournament.slots, "full slots");

        // take fund value in erc20
        address tokenAddress = tournamentToken[tournamentId];
        require(tokenAddress != address(0x0), "not erc20 tournament");
        require(IERC20Upgradeable(tokenAddress).transferFrom(sender, address(this), fundValue), "transfer fund failed");

        tournament.totalReward = tournament.totalReward + fundValue;

        emit TournamentFunded(sender, tournamentId, fundValue);
    }

    /**
     * @dev called by the user who want to participant in created tournament
     * user must pay fee which has set by the host in order to participate
     */
    function registerTournament(uint256 tournamentId) external payable whenNotPaused {
        Tournament storage tournament = tournaments[tournamentId];
        address sender = _msgSender();
        require(tournament.currentSlots < tournament.slots, "full slots");

        // take entry fee
        address tokenAddress = tournamentToken[tournamentId];
        if (tokenAddress == address(0x0)) {
            require(msg.value >= tournament.entryFee, "not enough money");
        } else {
            require(
                IERC20Upgradeable(tokenAddress).transferFrom(sender, address(this), tournament.entryFee),
                "transfer entry fee failed"
            );
        }

        // update storage
        tournament.currentSlots = tournament.currentSlots + 1;

        mapping(address => PARTICIPANT_STATE) storage participants_ = participants[tournamentId];
        require(participants_[sender] == PARTICIPANT_STATE.NOT_JOIN, "registered");

        participants_[sender] = PARTICIPANT_STATE.JOINED;

        emit TournamentRegistered(_msgSender(), tournamentId);
    }

    function referee() public view returns (address) {
        return _referee;
    }

    function setReferee(address referee_) external onlyRole(ADMIN_ROLE) {
        _referee = referee_;
    }

    /**
     * @dev called by the winner of the tournament
     * winner must have the signature provide by the platform in order to claim the reward
     */
    function claimTournamentReward(uint16 rank, uint256 tournamentId, bytes memory signature) external whenNotPaused {
        require(_referee != address(0), "no referee");
        require(rank < 4, "invalid rank");
        uint256[4] memory rewards = getTournamentRewards(tournamentId);
        uint256 reward = rewards[rank];
        require(reward > 0, "no reward");
        address tokenAddress = tournamentToken[tournamentId];
        require(
            address(this).balance > reward ||
                (tokenAddress != address(0x0) && IERC20Upgradeable(tokenAddress).balanceOf(address(this)) > reward),
            "not enough"
        );

        address sender = _msgSender();
        require(participants[tournamentId][sender] == PARTICIPANT_STATE.JOINED, "not participant");
        participants[tournamentId][sender] = PARTICIPANT_STATE.CLAIMED;

        // Verify signature
        bytes32 _messageHash = keccak256(abi.encodePacked(rank, sender, tournamentId));
        bool is_valid = VerifySignature.verify(_referee, _messageHash, signature);
        if (!is_valid) {
            revert("invalid signature");
        }

        // Transfer reward
        if (tokenAddress == address(0x0)) {
            address payable _to = payable(sender);
            _to.transfer(reward);
        } else {
            require(IERC20Upgradeable(tokenAddress).transfer(sender, reward), "transfer reward failed");
        }

        emit TournamentRewardClaimed(rank, sender, tournamentId, reward);
    }

    /**
     * @dev called by the winner of the pvp league
     * winner must have the signature provide by the platform in order to claim the reward
     */
    function claimPvpReward(
        uint16 rank,
        uint256 tournamentId,
        uint256 reward,
        bytes memory signature
    ) external whenNotPaused {
        require(_referee != address(0), "no referee");
        require(reward > 0, "no reward");
        require(address(this).balance >= reward, "not enough");

        address sender = _msgSender();
        require(participants[tournamentId][sender] != PARTICIPANT_STATE.CLAIMED, "claimed");
        participants[tournamentId][sender] = PARTICIPANT_STATE.CLAIMED;

        // Verify signature
        bytes32 _messageHash = keccak256(abi.encodePacked(rank, sender, tournamentId, reward));
        bool is_valid = VerifySignature.verify(_referee, _messageHash, signature);
        if (!is_valid) {
            revert("invalid signature");
        }

        // Transfer reward
        address payable _to = payable(sender);
        _to.transfer(reward);

        emit TournamentRewardClaimed(rank, sender, tournamentId, reward);
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function energyFee() public view returns (uint256) {
        return _energyFee;
    }

    /**
     * @dev called by the owner to set fee
     */
    function setEnergyFee(uint256 fee) external onlyRole(ADMIN_ROLE) {
        _energyFee = fee;
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
