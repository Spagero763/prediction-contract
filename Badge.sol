// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title AchievementBadge - Simple gas-efficient Badge NFT for Base
/// @notice Three default badges: 1=Thinking Fast, 2=Fluent English, 3=Fast Calculations
/// @dev One badge per wallet per type. tokenURI = baseURI + "<type>/<tokenId>.json"
contract AchievementBadge is ERC721, ERC721Burnable, Ownable {
    using Strings for uint256;

    // Next tokenId to mint (starts at 1)
    uint256 private _nextId = 1;

    // Base URI like "https://your-domain.com/metadata/"
    string private _baseTokenURI;

    // tokenId => badge type (1..3 by default)
    mapping(uint256 => uint8) public badgeTypeOf;

    // Track if a wallet has already claimed a specific badge type
    mapping(address => mapping(uint8 => bool)) public hasBadgeType;

    // Optional: names for each type (editable by owner)
    mapping(uint8 => string) public typeName;

    /// @dev OZ v5 requires passing initial owner; if using OZ v4.x, replace `Ownable(msg.sender)` with `Ownable()`.
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
        typeName[1] = "Thinking Fast";
        typeName[2] = "Fluent English";
        typeName[3] = "Fast Calculations";
    }

    // ---------------------------- Owner/Admin ----------------------------

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setTypeName(uint8 badgeType, string calldata newName) external onlyOwner {
        typeName[badgeType] = newName;
    }

    /// @notice Admin mint to any address (useful for testing/rewards)
    function adminMint(address to, uint8 badgeType) external onlyOwner returns (uint256 tokenId) {
        _validateType(badgeType);
        tokenId = _mintCore(to, badgeType);
    }

    // ----------------------------- Public --------------------------------

    /// @notice Claim one badge of a given type (one per wallet per type)
    function mintBadge(uint8 badgeType) external returns (uint256 tokenId) {
        _validateType(badgeType);
        require(!hasBadgeType[msg.sender][badgeType], "Already claimed this badge type");
        tokenId = _mintCore(msg.sender, badgeType);
    }

    /// @notice Read the badge type for a tokenId
    function getBadgeType(uint256 tokenId) external view returns (uint8) {
        _requireOwned(tokenId);
        return badgeTypeOf[tokenId];
    }

    // ---------------------------- Internals ------------------------------

    function _mintCore(address to, uint8 badgeType) internal returns (uint256 tokenId) {
        hasBadgeType[to][badgeType] = true;
        tokenId = _nextId++;
        badgeTypeOf[tokenId] = badgeType;
        _safeMint(to, tokenId);
        // (Optional) emit richer offchain analytics via event
        emit BadgeMinted(to, tokenId, badgeType);
    }

    function _validateType(uint8 badgeType) internal pure {
        require(badgeType >= 1 && badgeType <= 3, "Invalid badge type");
    }

    // ----------------------------- Metadata ------------------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Builds URIs like:
    ///      `${baseURI}${badgeType}/${tokenId}.json`
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory base = _baseURI();
        if (bytes(base).length == 0) return "";
        return string(
            abi.encodePacked(
                base,
                uint256(badgeTypeOf[tokenId]).toString(),
                "/",
                tokenId.toString(),
                ".json"
            )
        );
    }

    // ------------------------------ Events -------------------------------

    event BadgeMinted(address indexed to, uint256 indexed tokenId, uint8 indexed badgeType);
}
