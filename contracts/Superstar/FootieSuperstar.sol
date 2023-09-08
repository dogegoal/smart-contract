// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";

/// @title Players contract for Dogegoal Players. Holds all common structs, events and base variables.
/// @author Dogegoal
/// @dev The main Players contract.
contract FootieSuperstar is
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721RoyaltyUpgradeable,
    AccessControlUpgradeable
{
    /*** DATA TYPES ***/

    struct Player {
        // Player's attributes
        uint8 rarity;
        uint8 level;
        uint256 metaId;
    }

    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string public baseURI;

    /// @dev An mapping ID to the Player struct.
    mapping(uint256 => Player) private _players;
    uint256 private _totalSupply;

    event MintPlayer(address indexed user, uint256 indexed playerId, uint256 metaId);

    function initialize(address royaltyPayee_, uint96 feeNumerator_) public initializer {
        __ERC721_init("Footie Superstar", "Player");
        __AccessControl_init_unchained();
        _setDefaultRoyalty(royaltyPayee_, feeNumerator_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice public function for admin set base URI for NFT token.
    function setBaseURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        baseURI = _uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721PausableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function safeMint(
        address to,
        uint8 rarity_,
        uint256 metaId_
    ) external onlyRole(MINTER_ROLE) returns (uint256 newPlayerId) {
        newPlayerId = _totalSupply + 1;
        _safeMint(to, newPlayerId);

        _players[newPlayerId] = Player({rarity: rarity_, level: 1, metaId: metaId_});
        _totalSupply = newPlayerId;

        emit MintPlayer(to, newPlayerId, metaId_);
    }

    function burn(uint256 tokenId) public override onlyRole(BURNER_ROLE) whenNotPaused {
        super.burn(tokenId);
        _players[tokenId] = Player({rarity: 0, level: 0, metaId: 0});
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721RoyaltyUpgradeable, ERC721Upgradeable) onlyRole(BURNER_ROLE) {
        super._burn(tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns all the relevant information about a specific player.
    /// @param _id The ID of the player of interest.
    function getPlayer(uint256 _id) external view returns (address user, uint8 rarity, uint8 level, uint256 metaId) {
        require(_exists(_id), "ERC721: nonexistent token");
        Player storage player_ = _players[_id];
        user = ownerOf(_id);
        rarity = player_.rarity;
        level = player_.level;
        metaId = player_.metaId;
    }

    // @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721RoyaltyUpgradeable, ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
