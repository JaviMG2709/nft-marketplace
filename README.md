# NFT Marketplace — Fixed-Price ERC-721 Trading with Fees

[English](README.md) | [Español](README.es.md)

NFT Marketplace is a Solidity learning project built with Foundry. It is a non-custodial marketplace where NFT owners can create fixed-price ERC-721 listings, buyers can purchase them with ETH, and the marketplace collects fees from sellers and buyers.

## Features

- `listNFT(nftAddress, tokenId, price)` creates a fixed-price listing for an ERC-721 owned by the caller.
- The seller pays a non-refundable listing fee when creating the listing.
- `buyNFT(nftAddress, tokenId)` requires the buyer to pay the listed price plus the buyer fee. The seller receives the full listed price.
- `cancelList(nftAddress, tokenId)` lets only the listing seller cancel it. The listing fee is not refunded.
- The initial marketplace fee is **2.5%**, represented as `250` basis points. `10,000` basis points represent 100%.
- Each listing stores the fee rate active when it was created. Later fee changes do not affect existing listings.
- `setFee(newFeeBps)` lets only the contract owner update the fee for future listings. The contract currently imposes no maximum fee.
- `withdrawFees()` lets only the owner withdraw the fees accumulated by the marketplace.
- `calculateFee(price, feeBps)` calculates fees using OpenZeppelin's full-precision `Math.mulDiv`.
- `ReentrancyGuard` protects listing, purchase, cancellation, and fee-withdrawal operations.
- Events are emitted when an NFT is listed, sold, or cancelled and when the fee is updated or withdrawn.

## How fees work

For an NFT listed at `1 ETH` with the initial 2.5% fee:

| Action | Payer | Amount |
| --- | --- | ---: |
| Create the listing | Seller | `0.025 ETH` |
| Purchase the NFT | Buyer | `1.025 ETH` |
| Receive the sale price | Seller | `1 ETH` |
| Total marketplace fees | Marketplace | `0.05 ETH` |

The NFT remains in the seller's wallet while listed. Before a purchase can succeed, the seller must approve the marketplace to transfer that token. If a listing is cancelled, its listing fee remains in the marketplace.

## Deployment status

The marketplace has not been deployed to a public network yet. There is currently no deployment script or recorded broadcast in this repository.

## Tech stack

- Solidity `0.8.34`
- Foundry and Forge for compilation, testing, formatting, and coverage
- OpenZeppelin Contracts for `IERC721`, `Ownable`, `ReentrancyGuard`, and `Math`
- GitHub Actions for continuous integration

## Project structure

| Path | Purpose |
| --- | --- |
| `src/NFTMarketplace.sol` | Marketplace, listing, purchase, cancellation, and fee logic |
| `test/NFTMarketplaceTest.t.sol` | Unit tests and the mock ERC-721 used by the tests |
| `.github/workflows/test.yml` | CI checks for formatting, compilation, and tests |
| `foundry.toml` | Foundry configuration |
| `lib/` | Git submodules containing Foundry and OpenZeppelin dependencies |

## Getting started

Install [Foundry](https://getfoundry.sh/) and Git, then clone the repository with its submodules:

```bash
git clone --recurse-submodules <repository-url>
cd nft-marketplace
```

If the repository was cloned without submodules:

```bash
git submodule update --init --recursive
```

Build the contracts and check their formatting:

```bash
forge build
forge fmt --check
```

Run the tests and coverage report:

```bash
forge test -vvv
forge coverage
```

## Testing and current scope

The project currently has **22 automated tests** covering minting the mock NFT, listing and cancellation behavior, purchases, NFT transfers, seller payments, listing and buyer fees, fee snapshots, owner permissions, and fee withdrawals.

Current coverage for `src/NFTMarketplace.sol` is:

- Lines: **100%**
- Statements: **100%**
- Functions: **100%**
- Branches: **88.89%**

The two uncovered branches are the failure paths where a contract acting as the seller or marketplace owner deliberately rejects an ETH transfer.

The GitHub Actions workflow runs formatting checks, compilation, and the complete test suite on pushes and pull requests.

This is a learning project and has not been audited for production use. The current version supports fixed-price ERC-721 sales paid in ETH. It does not yet include auctions, offers, ERC-20 payments, ERC-2981 royalties, pausing, a fee cap, listing pagination, or an on-chain listing index. Ownership or approval of an NFT can also change after it is listed, causing a later purchase to revert.

## What I am learning

- Building a non-custodial ERC-721 marketplace.
- Applying the checks-effects-interactions pattern and reentrancy protection.
- Representing percentages with basis points and calculating fees safely.
- Managing owner-only configuration and withdrawals.
- Testing successful operations, expected reverts, balances, ownership transfers, and access control with Foundry.
- Measuring smart-contract coverage and understanding uncovered branches.

## Next steps

- Add a deployment script and deploy the marketplace to a test network.
- Build a frontend for connecting a wallet, browsing listings, approving NFTs, listing, buying, and cancelling.
- Add a backend or blockchain indexer to consume marketplace events and provide searchable listing history.
- Add pagination or an indexing strategy for active listings.
- Consider ERC-2981 royalty support and ERC-20 payment tokens.
- Consider a maximum fee, pausing, and two-step ownership transfer for safer administration.
- Improve payment handling so contracts that reject ETH cannot block purchases or fee withdrawals.
- Run static analysis and obtain a security review before any production deployment.
