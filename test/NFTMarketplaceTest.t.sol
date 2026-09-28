// SPDX-License-Identifier: MIT

pragma solidity 0.8.34;

import "forge-std/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../src/NFTMarketplace.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }
}

contract NFTMarketplaceTest is Test {
    NFTMarketplace marketplace;
    MockNFT nft;
    address deployer = vm.addr(1);
    address user = vm.addr(2);
    uint256 tokenId = 0;

    function setUp() public {
        vm.startPrank(deployer);
        marketplace = new NFTMarketplace();
        nft = new MockNFT();
        vm.stopPrank();

        vm.startPrank(user);
        nft.mint(user, 0);
        vm.stopPrank();
    }

    function testMintNFT() public view {
        address ownerOf = nft.ownerOf(tokenId);
        assert(ownerOf == user);
    }

    function testShouldRevertIfPriceIsZero() public {
        vm.startPrank(user);

        vm.expectRevert("Price cannot be 0");
        marketplace.listNFT(address(nft), tokenId, 0);

        vm.stopPrank();
    }

    function testShouldRevertIfNotOwner() public {
        vm.startPrank(user);

        address user2_ = vm.addr(3);
        uint256 tokenId_ = 1;
        nft.mint(user2_, tokenId_);

        vm.expectRevert("You are not the owner of the NFT");
        marketplace.listNFT(address(nft), tokenId_, 1 ether);

        vm.stopPrank();
    }

    function testListNFTCorrectly() public {
        vm.startPrank(user);

        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());
        vm.deal(user, fee);

        (address sellerBefore,,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);
        (address sellerAfter,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        vm.stopPrank();
    }

    function testCanNotListNFTWithIncorrectFee() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.startPrank(user);

        vm.expectRevert("Incorrect listing fee");
        marketplace.listNFT{value: fee - 1}(address(nft), tokenId, price);

        vm.stopPrank();
    }

    function testListingFeeIsAccumulated() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.prank(user);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        assert(marketplace.accumulatedFees() == fee);
        assert(address(marketplace).balance == fee);
    }

    function testCancelListShouldRevertIfNotOwner() public {
        vm.startPrank(user);

        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());
        vm.deal(user, fee);

        (address sellerBefore,,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);
        (address sellerAfter,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        vm.stopPrank();

        address user2 = vm.addr(3);
        vm.startPrank(user2);

        vm.expectRevert("You are not the listing owner");
        marketplace.cancelList(address(nft), tokenId);

        vm.stopPrank();
    }

    function testCancelListShouldWorkCorrectly() public {
        vm.startPrank(user);

        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());
        vm.deal(user, fee);

        (address sellerBefore,,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);
        (address sellerAfter,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        marketplace.cancelList(address(nft), tokenId);
        (address sellerAfter2,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerAfter2 == address(0));

        vm.stopPrank();
    }

    function testListingFeeIsNotRefundedAfterCancellation() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.startPrank(user);

        marketplace.listNFT{value: fee}(address(nft), tokenId, price);
        marketplace.cancelList(address(nft), tokenId);

        vm.stopPrank();

        assert(address(user).balance == 0);
        assert(marketplace.accumulatedFees() == fee);
        assert(address(marketplace).balance == fee);
    }

    function testCanNotBuyUnlistedNFT() public {
        address user2 = vm.addr(3);
        vm.startPrank(user2);

        vm.expectRevert("Listing does not exist");
        marketplace.buyNFT(address(nft), tokenId);

        vm.stopPrank();
    }

    function testCanNotBuyWithIncorrectPayment() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.startPrank(user);

        vm.deal(user, fee);

        (address sellerBefore,,,,) = marketplace.listing(address(nft), tokenId);

        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        (address sellerAfter,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        vm.stopPrank();

        address user2 = vm.addr(3);
        uint256 totalPrice = price + fee;

        vm.deal(user2, totalPrice);
        vm.startPrank(user2);

        vm.expectRevert("Incorrect price");
        marketplace.buyNFT{value: totalPrice - 1}(address(nft), tokenId);

        vm.stopPrank();
    }

    function testShouldBuyNFTCorrectly() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.startPrank(user);

        vm.deal(user, fee);

        (address sellerBefore,,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);
        (address sellerAfter,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore == address(0) && sellerAfter == user);

        nft.approve(address(marketplace), tokenId);
        vm.stopPrank();

        address user2 = vm.addr(3);
        uint256 totalPrice = price + fee;

        vm.deal(user2, totalPrice);
        vm.startPrank(user2);

        (address sellerBefore2,,,,) = marketplace.listing(address(nft), tokenId);
        marketplace.buyNFT{value: totalPrice}(address(nft), tokenId);
        (address sellerAfter2,,,,) = marketplace.listing(address(nft), tokenId);

        assert(sellerBefore2 == user && sellerAfter2 == address(0));

        vm.stopPrank();
    }

    function testNFTTransferredCorrectly() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.startPrank(user);

        nft.approve(address(marketplace), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        address ownerBefore = nft.ownerOf(tokenId);

        vm.stopPrank();

        address user2 = vm.addr(3);
        uint256 totalPrice = price + fee;

        vm.deal(user2, totalPrice);
        vm.prank(user2);
        marketplace.buyNFT{value: totalPrice}(address(nft), tokenId);

        address ownerAfter = nft.ownerOf(tokenId);

        assert(ownerBefore == user && ownerAfter == user2);
    }

    function testSellerReceivesCorrectEtherAmount() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.startPrank(user);

        nft.approve(address(marketplace), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        vm.stopPrank();

        uint256 balanceBefore = address(user).balance;

        address user2 = vm.addr(3);
        uint256 totalPrice = price + fee;

        vm.deal(user2, totalPrice);
        vm.prank(user2);
        marketplace.buyNFT{value: totalPrice}(address(nft), tokenId);

        uint256 balanceAfter = address(user).balance;

        assert(balanceAfter == balanceBefore + price);
    }

    function testListingAndBuyerFeesAreAccumulated() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.startPrank(user);

        nft.approve(address(marketplace), tokenId);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        vm.stopPrank();

        address user2 = vm.addr(3);
        uint256 totalPrice = price + fee;

        vm.deal(user2, totalPrice);
        vm.prank(user2);
        marketplace.buyNFT{value: totalPrice}(address(nft), tokenId);

        assert(marketplace.accumulatedFees() == fee * 2);
        assert(address(marketplace).balance == fee * 2);
    }

    function testInitialFeeIsCorrect() public view {
        uint256 price = 1 ether;

        assert(marketplace.feeBps() == 250);
        assert(marketplace.calculateFee(price, marketplace.feeBps()) == 0.025 ether);
    }

    function testOwnerCanChangeFeeWithoutMaximum() public {
        uint256 newFeeBps = 20_000;

        vm.prank(deployer);
        marketplace.setFee(newFeeBps);

        assert(marketplace.feeBps() == newFeeBps);
    }

    function testCanNotChangeFeeIfNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        marketplace.setFee(500);

        vm.stopPrank();
    }

    function testListingKeepsOriginalFeeAfterFeeChange() public {
        uint256 price = 1 ether;
        uint256 originalFeeBps = marketplace.feeBps();
        uint256 fee = marketplace.calculateFee(price, originalFeeBps);

        vm.deal(user, fee);
        vm.prank(user);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        vm.prank(deployer);
        marketplace.setFee(500);

        (,,,, uint256 listingFeeBps) = marketplace.listing(address(nft), tokenId);

        assert(marketplace.feeBps() == 500);
        assert(listingFeeBps == originalFeeBps);
    }

    function testOwnerCanWithdrawFees() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.prank(user);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        uint256 balanceBefore = address(deployer).balance;

        vm.prank(deployer);
        marketplace.withdrawFees();

        uint256 balanceAfter = address(deployer).balance;

        assert(balanceAfter == balanceBefore + fee);
        assert(marketplace.accumulatedFees() == 0);
        assert(address(marketplace).balance == 0);
    }

    function testCanNotWithdrawFeesIfNotOwner() public {
        uint256 price = 1 ether;
        uint256 fee = marketplace.calculateFee(price, marketplace.feeBps());

        vm.deal(user, fee);
        vm.prank(user);
        marketplace.listNFT{value: fee}(address(nft), tokenId, price);

        vm.startPrank(user);

        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        marketplace.withdrawFees();

        vm.stopPrank();
    }

    function testCanNotWithdrawIfThereAreNoFees() public {
        vm.startPrank(deployer);

        vm.expectRevert("No fees to withdraw");
        marketplace.withdrawFees();

        vm.stopPrank();
    }
}
