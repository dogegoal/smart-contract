// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/// @title Characters contract for Dogegoal Characters. Holds all common structs, events and base variables.
/// @author Dogegoal
/// @dev The main Characters contract.
contract FootieSuperstar is ERC721Upgradeable, AccessControlUpgradeable {
    /*** DATA TYPES ***/

    function initialize() public initializer {
        __ERC721_init("Footie Superstar", "Player");
        __AccessControl_init_unchained();
    }

    // @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
