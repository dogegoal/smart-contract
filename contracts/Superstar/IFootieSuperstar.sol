// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IFootieSuperstar is IERC721Upgradeable {
    function safeMint(address to, uint8 rarity_, uint256 metaId_) external returns (uint256 newPlayerId);
}
