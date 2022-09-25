// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

contract PromiseLand is ERC721URIStorage, ERC2981, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 public likingPrice = 0.01 ether;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        address creator;
        address owner;
        uint256 price;
        uint256 likes;
        uint256 dislikes;
        bool selling;
        bool reselling;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address creator,
        address owner,
        uint256 price,
        uint256 likes,
        uint256 dislikes,
        bool selling,
        bool reselling
    );

    event MarketItemOnSale(uint256 indexed tokenId, uint256 price);
    event MarketItemSold(uint256 indexed tokenId, uint256 price);
    event MarketItemLiked(uint256 indexed tokenId, address liker, uint256 likePrice);
    event MarketItemDisliked(uint256 indexed tokenId, address disliker, uint256 dislikePrice);

    constructor() ERC721("PromiseLand", "PL") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burnNFT(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);

        idToMarketItem[tokenId].owner = to;
        idToMarketItem[tokenId].reselling = false;
        idToMarketItem[tokenId].selling = false;
    }

    /* Mints a nft token */
    function createToken(
        string memory tokenURI_
    ) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI_);

         idToMarketItem[newTokenId] = MarketItem(
            newTokenId,
            payable(msg.sender),
            payable(msg.sender),
            0,
            0,
            0,
            false,
            true
        );

        emit MarketItemCreated(newTokenId, msg.sender, msg.sender, 0, 0, 0, false, true);

        return newTokenId;
    }

    /* Updates the listing price of a token */
    function updateListingPrice(uint256 tokenId, uint256 _listingPrice) public payable {
        require(
            ownerOf(tokenId) == msg.sender,
            "Only nft owner can update listing price."
        );

        idToMarketItem[tokenId].price = _listingPrice;
        idToMarketItem[tokenId].selling = true;

        if (!idToMarketItem[tokenId].reselling) {
            _itemsSold.decrement();
            idToMarketItem[tokenId].reselling = true;
        }

        emit MarketItemOnSale(tokenId, _listingPrice);
    }

    /* Transfers ownership of the item, as well as funds between parties */
    function executeSale(uint256 tokenId) public payable {
        address seller = ownerOf(tokenId);
        require(
            msg.value >= idToMarketItem[tokenId].price,
            "Please submit the asking price in order to complete the purchase"
        );
        _itemsSold.increment();
        _transfer(seller, msg.sender, tokenId);
        payable(seller).transfer(msg.value);

        emit MarketItemSold(tokenId, msg.value);
    }

    /* Returns the listing price of a token */
    function getListingPrice(uint256 tokenId) public view returns (uint256) {
        return idToMarketItem[tokenId].price;
    }

    function likeNft(uint256 tokenId) public payable nonReentrant {
        require(
            msg.value >= likingPrice,
            "Price must be equal to liking price"
        );
        idToMarketItem[tokenId].likes += 1;

        // send to token owner
        payable(ownerOf(tokenId)).transfer(msg.value);

        emit MarketItemLiked(tokenId, msg.sender, msg.value);
    }

    function dislikeNft(uint256 tokenId) public payable {
        require(
            _exists(tokenId),
            "NF" // not found
        );

        require(
            msg.value >= likingPrice,
            "Price must be equal to liking price"
        );

        idToMarketItem[tokenId].dislikes += 1;

        emit MarketItemDisliked(tokenId, msg.sender, msg.value);
    }

    function getNftLikes (uint256 tokenId) public view returns (uint256) {
         return idToMarketItem[tokenId].likes;
    }

    function getNftDislikes (uint256 tokenId) public view returns (uint256) {
         return idToMarketItem[tokenId].dislikes;
    }

    /* Returns the Nft by Id */
    function fetchNftById(uint256 tokenId) public view returns (MarketItem memory) {
        return idToMarketItem[tokenId];
    }

    /* Returns all selling items, for demo purpose only, should move to use theGraph */
    function fetchSellingNfts() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns all created items, for demo purpose only, should move to use theGraph */
    function fetchAllNfts() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 currentIndex = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return items;
    }

    /* Returns only items that a user has owned, for demo purpose only, should move to use theGraph */
    function fetchUserOwnedNfts(address userAddress) public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == userAddress) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == userAddress) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has created, for demo purpose only, should move to use theGraph */
    function fetchUserCreatedNfts(address userAddress) public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == userAddress) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].creator == userAddress) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }


}
