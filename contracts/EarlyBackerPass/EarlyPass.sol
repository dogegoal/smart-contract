// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";

/// @title Dogegoal Early Pass NFT
/// @author Dogegoal
/// @dev The main early backer pass contract. 2 types : Starter Pass - Pro Pass
contract EarlyPass is
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721RoyaltyUpgradeable,
    AccessControlUpgradeable
{
    // Consts
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Storage
    // @dev tokenId => PassType
    mapping(uint256 => uint256) private _passTypes;
    // @dev PassType => URI
    mapping(uint256 => string) private _passURIs;

    function initialize(address royaltyPayee_, uint96 feeNumerator_) public initializer {
        __ERC721_init("Dogegoal Early Pass", "Pass");
        __AccessControl_init_unchained();
        _setDefaultRoyalty(royaltyPayee_, feeNumerator_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }

    function updatePassURI(uint256 passType_, string calldata passURI_) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _passURIs[passType_] = passURI_;
    }

    function safeMint(address to, uint256 tokenId, uint256 passType_) external onlyRole(MINTER_ROLE) whenNotPaused {
        _safeMint(to, tokenId);
        _passTypes[tokenId] = passType_;
    }

    function burn(uint256 tokenId) public override onlyRole(BURNER_ROLE) whenNotPaused {
        super.burn(tokenId);
        _passTypes[tokenId] = 0;
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

    function passType(uint256 tokenId) public view returns (uint256) {
        return _passTypes[tokenId];
    }

    function passURI(uint256 passType_) public view returns (string memory) {
        return _passURIs[passType_];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        uint256 _passType = passType(tokenId);
        string memory _tokenURI = _passURIs[_passType];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721RoyaltyUpgradeable, ERC721Upgradeable) onlyRole(BURNER_ROLE) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721PausableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    // @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721RoyaltyUpgradeable, ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
