//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract MarketPlace is ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemSold;

    address payable owner;
    uint listingPrice = 0.1 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct marketItem{
        uint itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        address payable owner;
        uint price;
        bool sold;
    }

    mapping(uint => marketItem) private idToMarketItem;

    event marketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address seller,
        address owner,
        uint price,
        bool sold
    );

    function getListingPrice() public view returns(uint){
        return listingPrice; 
    }

    function creatingItem(address nftContract, uint tokenId, uint price) public payable nonReentrant {
        require(price > 0,"Enter higher value");
        require(msg.value == listingPrice,"Invalid Listing price");
        _itemIds.increment();
        uint itemId = _itemIds.current();
        idToMarketItem[itemId] = marketItem(itemId, nftContract, tokenId, payable(msg.sender), payable(address(0)), price, false);
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit marketItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price, false);
    }

    function sellingNft(address nftContract, uint itemId) public payable nonReentrant{
        uint price = idToMarketItem[itemId].price;
        uint tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price,"Invalid price");
        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function getMarketItems() public view returns(marketItem[] memory){
        uint itemCount = _itemIds.current();
        uint unsoldItems = _itemIds.current() - _itemSold.current();
        uint currentIndex = 0;

        marketItem[] memory items = new marketItem[](unsoldItems);
        for (uint i = 0; i < itemCount; i++){
            if (idToMarketItem[i+1].owner == address(0)){
                uint currentId = i+1;
                marketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;  
                currentIndex += 1;
            }
        }
        return items;
    }

    function getMyNft() public view returns(marketItem[] memory){
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                itemCount += 1;
            }
        }

        marketItem[] memory items = new marketItem[](itemCount);
        for( uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                uint currentId = i+1;
                marketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getCreatedNft() public view returns(marketItem[] memory){
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        marketItem[] memory items = new marketItem[](itemCount);
        for( uint i = 0; i < totalItemCount; i++){
            if(idToMarketItem[i+1].seller == msg.sender){
                uint currentId = i + 1;
                marketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1 ;
            }
        }
        return items;
    }
}