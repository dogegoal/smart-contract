// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IEarlyPack is IERC721Upgradeable {
    function safeMint(address to, uint256 tokenId, uint256 packType_) external;

    function burn(uint256 tokenId) external;
}
