# Gaming NFT Marketplace Smart Contract

A comprehensive blockchain-based platform for in-game asset ownership, trading, and player progression tracking. This smart contract enables players to mint, trade, and manage digital gaming assets with built-in marketplace functionality.

## Features

- **Asset Creation**: Mint individual or batch gaming NFTs with metadata
- **Asset Transfer**: Transfer ownership of gaming assets between players
- **Marketplace**: Built-in marketplace for listing and purchasing assets
- **Player Progression**: Track player statistics including experience points and levels
- **Batch Operations**: Efficient bulk operations for game integration

## Contract Overview

### Core Components

1. **Gaming Asset Registry**: Central registry for all gaming assets
2. **Player Progression System**: Track player experience and levels
3. **Marketplace System**: Decentralized trading platform
4. **Batch Operations**: Support for multiple operations in single transactions

### Key Constants

- **Maximum Player Level**: 100
- **Maximum Experience Points**: 10,000
- **Maximum Metadata URI Length**: 256 characters
- **Maximum Batch Size**: 10 operations per transaction

## Functions

### Asset Creation

#### `create-single-gaming-asset`
Creates a single gaming asset with specified metadata.

**Parameters:**
- `metadata-uri` (string-utf8 256): URI pointing to asset metadata
- `is-transferable` (bool): Whether the asset can be transferred

**Access:** Contract deployer only

**Returns:** Asset identifier (uint)

#### `create-multiple-gaming-assets`
Creates multiple gaming assets in a single transaction.

**Parameters:**
- `metadata-uri-list` (list 10 string-utf8): List of metadata URIs
- `transferability-settings` (list 10 bool): Transferability settings for each asset

**Access:** Contract deployer only

**Returns:** List of created asset identifiers

### Asset Transfer

#### `transfer-single-gaming-asset`
Transfers ownership of a single gaming asset.

**Parameters:**
- `asset-identifier` (uint): ID of the asset to transfer
- `recipient-address` (principal): Address of the new owner

**Access:** Current asset owner

**Requirements:**
- Asset must be transferable
- Sender must be current owner
- Recipient cannot be the sender

#### `transfer-multiple-gaming-assets`
Transfers multiple assets to different recipients in batch.

**Parameters:**
- `asset-identifier-list` (list 10 uint): List of asset IDs
- `recipient-address-list` (list 10 principal): List of recipient addresses

**Access:** Current asset owners

### Marketplace Functions

#### `create-marketplace-listing`
Lists an asset for sale on the marketplace.

**Parameters:**
- `asset-identifier` (uint): ID of the asset to list
- `asking-price` (uint): Price in microSTX

**Requirements:**
- Asset must be owned by sender
- Asset must be transferable
- Price must be greater than 0

#### `execute-asset-purchase`
Purchases a listed asset from the marketplace.

**Parameters:**
- `asset-identifier` (uint): ID of the asset to purchase

**Requirements:**
- Asset must be listed
- Buyer cannot be the seller
- Buyer must have sufficient STX balance

#### `remove-marketplace-listing`
Removes an asset listing from the marketplace.

**Parameters:**
- `asset-identifier` (uint): ID of the asset to delist

**Access:** Listing owner only

### Player Progression

#### `update-player-progression-statistics`
Updates player statistics and progression data.

**Parameters:**
- `experience-points` (uint): Total experience points (max 10,000)
- `player-level` (uint): Current player level (max 100)

**Access:** Any player (updates their own data)

## Read-Only Functions

### `get-gaming-asset-information`
Retrieves detailed information about a gaming asset.

**Parameters:**
- `asset-identifier` (uint): Asset ID

**Returns:**
```clarity
{
  current-owner: principal,
  metadata-location: (string-utf8 256),
  is-transferable: bool
}
```

### `get-marketplace-listing-information`
Retrieves marketplace listing details.

**Parameters:**
- `asset-identifier` (uint): Asset ID

**Returns:**
```clarity
{
  listing-owner: principal,
  asking-price: uint,
  listing-block-height: uint
}
```

### `get-player-progression-information`
Retrieves player progression data.

**Parameters:**
- `player-address` (principal): Player's address

**Returns:**
```clarity
{
  total-experience: uint,
  current-level: uint
}
```

### `get-total-gaming-assets-count`
Returns the total number of gaming assets created.

**Returns:** Total asset count (uint)

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | Caller lacks required permissions |
| 101 | ERR-ASSET-NOT-FOUND | Asset does not exist |
| 102 | ERR-FORBIDDEN-ACTION | Action not allowed |
| 103 | ERR-INVALID-PARAMETERS | Invalid function parameters |
| 104 | ERR-INVALID-PRICE-AMOUNT | Invalid price specified |
| 105 | ERR-MARKETPLACE-LISTING-NOT-FOUND | Marketplace listing not found |

## Usage Examples

### Creating Assets
```clarity
;; Create a single gaming asset
(contract-call? .gaming-nft-marketplace create-single-gaming-asset 
  "https://metadata.example.com/sword-001.json" 
  true)

;; Create multiple assets
(contract-call? .gaming-nft-marketplace create-multiple-gaming-assets
  (list "https://metadata.example.com/sword-001.json" 
        "https://metadata.example.com/armor-001.json")
  (list true true))
```

### Trading Assets
```clarity
;; List asset for sale
(contract-call? .gaming-nft-marketplace create-marketplace-listing u1 u1000000)

;; Purchase asset
(contract-call? .gaming-nft-marketplace execute-asset-purchase u1)

;; Transfer asset directly
(contract-call? .gaming-nft-marketplace transfer-single-gaming-asset 
  u1 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Player Progression
```clarity
;; Update player stats
(contract-call? .gaming-nft-marketplace update-player-progression-statistics 
  u2500 
  u25)
```

## Integration Guidelines

### For Game Developers

1. **Asset Creation**: Use batch creation functions for efficient minting
2. **Metadata Standards**: Follow established NFT metadata standards (JSON)
3. **Player Integration**: Link player addresses to game accounts
4. **Event Handling**: Monitor blockchain events for real-time updates

### Security Considerations

- Only contract deployer can mint new assets
- Transferability is set at creation and cannot be changed
- Marketplace listings are automatically removed upon purchase
- Player progression data is self-managed by players