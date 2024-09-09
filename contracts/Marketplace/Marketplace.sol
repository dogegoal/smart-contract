// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Superstar/IFootieSuperstar.sol";

contract Marketplace is IERC721ReceiverUpgradeable, OwnableUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    ///////////// Contants
    bytes32 constant WITHDRAWER = keccak256("WITHDRAWER");
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 constant DEFAULT_PLATFORM_FEE = 200;
    uint256 constant FEE_DENOMINATOR = 10000;

    ///////////// Structs
    struct Order {
        bytes32 id;
        address seller;
        uint256 price;
    }

    ///////////// Storages
    // Mapping from ERC721 id to Order
    mapping(uint256 => Order) public orders;
    // The platform fee in percent, buyer will pay for this
    uint256 public platformFee;
    IFootieSuperstar private _nftContract;

    ///////////// Events
    // Orders
    event CreateOrder(
        bytes32 id,
        uint256 indexed nftId,
        address indexed seller,
        uint256 price,
        uint256 feeCharged,
        uint256 royaltyFee
    );
    event ExecuteOrder(
        bytes32 id,
        uint256 indexed nftId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 feeCharged,
        uint256 royaltyFee
    );
    event CancelOrder(bytes32 id, uint256 indexed nftId, address indexed seller);

    // Withdraw
    event Withdraw(address receiver, uint256 amount);

    function initialize(address nftContract_) public initializer {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _nftContract = IFootieSuperstar(nftContract_);

        platformFee = DEFAULT_PLATFORM_FEE;
    }

    /**
     * @dev function to update the platform fee that's charged to users who buys item
     * @param _platformFee the platform fee
     */
    function setPlatformFee(uint256 _platformFee) external onlyRole(ADMIN_ROLE) {
        require(_platformFee < FEE_DENOMINATOR, "invalid fee");
        platformFee = _platformFee;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev function to create a new order
     * @param nftId - id of NFT
     * @param price - the selling price
     */
    function createOrder(uint256 nftId, uint256 price) public whenNotPaused {
        _createOrder(_msgSender(), nftId, price);
    }

    /**
     * @dev function to pay order
     * @param nftId - ID of NFT
     */
    function executeOrder(uint256 nftId) public payable whenNotPaused {
        _executeOrder(_msgSender(), nftId);
    }

    /**
     * @dev cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param nftId - ID of NFT
     */
    function cancelOrder(uint256 nftId) public whenNotPaused {
        _cancelOrder(_msgSender(), nftId);
    }

    function _createOrder(address seller, uint256 nftId, uint256 price) internal {
        address assetOwner = _nftContract.ownerOf(nftId);

        require(seller == assetOwner, "not owner");
        require(price > 0, "invalid price");

        uint256 feeCharged = 0;
        if (platformFee > 0) {
            feeCharged = (price * platformFee) / FEE_DENOMINATOR;
        }

        bytes32 orderId = keccak256(abi.encodePacked(block.timestamp, assetOwner, nftId, price));
        orders[nftId] = Order({id: orderId, seller: assetOwner, price: price});

        // Deposit NFT to SMC
        _nftContract.safeTransferFrom(seller, address(this), nftId);

        (, uint256 royaltyFee) = _nftContract.royaltyInfo(nftId, price);
        emit CreateOrder(orderId, nftId, assetOwner, price, feeCharged, royaltyFee);
    }

    function _cancelOrder(address sender, uint256 nftId) internal {
        Order memory order = orders[nftId];

        require(order.id != 0, "not published");
        require(order.seller == sender || hasRole(ADMIN_ROLE, sender), "unauthorized");

        bytes32 orderId = order.id;
        address seller = order.seller;
        delete orders[nftId];

        // transfer ship to seller
        _nftContract.safeTransferFrom(address(this), seller, nftId);

        emit CancelOrder(orderId, nftId, seller);
    }

    function _executeOrder(address buyer, uint256 nftId) internal {
        Order memory order = orders[nftId];

        address seller = order.seller;
        require(seller != address(0x0), "no order");
        require(seller != buyer, "invalid buyer");
        require(msg.value >= order.price, "not enough money");

        bytes32 orderId = order.id;
        uint256 price = order.price;
        uint256 feeCharged = (price * platformFee) / 10000;
        (address payee, uint256 royaltyFee) = _nftContract.royaltyInfo(nftId, price);
        delete orders[nftId];

        // transfer royalty fee
        payable(payee).transfer(royaltyFee);

        // transfer sale amount to seller
        payable(seller).transfer(price - feeCharged - royaltyFee);

        // transfer ship owner
        _nftContract.safeTransferFrom(address(this), buyer, nftId);

        emit ExecuteOrder(orderId, nftId, seller, buyer, price, feeCharged, royaltyFee);
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

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
