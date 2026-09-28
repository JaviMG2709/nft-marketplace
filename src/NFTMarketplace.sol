// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

contract NFTMarketplace is Ownable, ReentrancyGuard {
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public feeBps = 250;
    uint256 public accumulatedFees;

    struct Listing {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        uint256 feeBps;
    }

    mapping(address => mapping(uint256 => Listing)) public listing;

    event NFTListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price,
        uint256 feeBps,
        uint256 listingFee
    );
    event NFTCancelled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event NFTSold(
        address indexed buyer,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 buyerFee
    );
    event FeeUpdated(uint256 previousFeeBps, uint256 newFeeBps);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {}

    // List an NFT
    function listNFT(address nftAddress_, uint256 tokenId_, uint256 price_) external payable nonReentrant {
        require(price_ > 0, "Price cannot be 0");

        address owner_ = IERC721(nftAddress_).ownerOf(tokenId_);
        require(owner_ == msg.sender, "You are not the owner of the NFT");

        uint256 listingFee_ = calculateFee(price_, feeBps);
        require(msg.value == listingFee_, "Incorrect listing fee");

        Listing memory listing_ =
            Listing({seller: msg.sender, nftAddress: nftAddress_, tokenId: tokenId_, price: price_, feeBps: feeBps});

        listing[nftAddress_][tokenId_] = listing_;
        accumulatedFees += listingFee_;

        emit NFTListed(msg.sender, nftAddress_, tokenId_, price_, feeBps, listingFee_);
    }

    // Buy an NFT
    function buyNFT(address nftAddress_, uint256 tokenId_) external payable nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];

        require(listing_.price > 0, "Listing does not exist");

        uint256 buyerFee_ = calculateFee(listing_.price, listing_.feeBps);
        require(msg.value == listing_.price + buyerFee_, "Incorrect price");

        delete listing[nftAddress_][tokenId_];
        accumulatedFees += buyerFee_;

        emit NFTSold(msg.sender, listing_.seller, listing_.nftAddress, listing_.tokenId, listing_.price, buyerFee_);

        IERC721(nftAddress_).safeTransferFrom(listing_.seller, msg.sender, listing_.tokenId);

        (bool success,) = listing_.seller.call{value: listing_.price}("");
        require(success, "Seller payment failed");
    }

    // Cancel a listing
    function cancelList(address nftAddress_, uint256 tokenId_) external nonReentrant {
        Listing memory listing_ = listing[nftAddress_][tokenId_];

        require(listing_.seller == msg.sender, "You are not the listing owner");

        delete listing[nftAddress_][tokenId_];

        emit NFTCancelled(msg.sender, nftAddress_, tokenId_);
    }

    function setFee(uint256 newFeeBps_) external onlyOwner {
        uint256 previousFeeBps_ = feeBps;
        feeBps = newFeeBps_;

        emit FeeUpdated(previousFeeBps_, newFeeBps_);
    }

    // Fees
    function withdrawFees() external nonReentrant onlyOwner {
        uint256 amount_ = accumulatedFees;
        require(amount_ > 0, "No fees to withdraw");

        accumulatedFees = 0;
        address recipient_ = owner();

        emit FeesWithdrawn(recipient_, amount_);

        (bool success,) = recipient_.call{value: amount_}("");
        require(success, "Fee withdrawal failed");
    }

    function calculateFee(uint256 price_, uint256 feeBps_) public pure returns (uint256) {
        return Math.mulDiv(price_, feeBps_, BPS_DENOMINATOR);
    }
}
