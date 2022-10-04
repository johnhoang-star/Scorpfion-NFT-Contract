//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; // security against transactions for multiple requests
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./NFT.sol";

contract Marketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter public itemIds;
    Counters.Counter public Count_Minted;
    Counters.Counter public Count_Listed;

    address public ScorpionNFTAddr;
    address public marketingWallet;
    uint256[] public nftprice;
    uint256 public royalties;

    struct MarketItem {
        address payable holder;
        uint256 price;
        bool listed;
        uint8 level;
    }

    // tokenId return which MarketToken
    mapping(uint32 => MarketItem) public marketItembyId;
    // Id List return by holder
    mapping(address => uint32[]) private itemsbyHolder;

    // listen to events from front end applications
    event EV_NFT_Minted(
        uint32 tokenId,
        uint8 level,
        uint256 price,
        address creator,
        bool listed,
        uint256 timeStamp
    );

    event EV_NFT_Listed(
        uint32 tokenId,
        address holder,
        uint256 price,
        bool listed,
        uint256 timeStamp
    );

    event EV_NFT_Purchased(
        uint32 tokenId,
        address from,
        address to,
        uint256 price,
        uint256 timeStamp
    );

    event EV_NFT_Ready(
        uint32 tokenId,
        uint256 price,
        uint8 level
    );

    constructor() {
    }
    
    function setScorp(address addr) public onlyOwner {
        ScorpionNFTAddr = addr;
    }

    function setMarketingWallet(address addr) public onlyOwner {
        marketingWallet = addr;
    }

    function check_minted(uint32 id) public view returns (bool) {
        return marketItembyId[id].holder == address(0) ? false : true;
    }

    function init(uint32 _begin, uint32 _end, uint8 _level) public onlyOwner {
        for(uint32 i = _begin;i<=_end; i++) {
            makeMarketItem(_level, i);
        }
    }

    function makeMarketItem(uint8 level, uint32 id) public onlyOwner {
        uint256 price;
        if(level == 4)
            price = nftprice[3];
        else if(level == 3)
            price = nftprice[2];
        else if(level == 2)
            price = nftprice[1];
        else if(level == 1)
            price = nftprice[0];

        marketItembyId[id] = MarketItem(
            payable(address(0)),
            price,
            false,
            level
        );

        emit EV_NFT_Ready(id, price, level);
    }
   
    function claim(address payable receiver) external onlyOwner {
        receiver.transfer(address(this).balance);
    }

    // @notice function to create a market to put it up for sale
    // @params _nftContract
    function mintNFT(
        uint32 _tokenId
    ) public payable nonReentrant {
        require(marketItembyId[_tokenId].holder == address(0), "This NFT Id is already minted");

        uint256 _defaultprice = marketItembyId[_tokenId].price;
        require(msg.value >= _defaultprice, "This NFT should be paid to mint");

        ScorpionNFT(ScorpionNFTAddr).mintToken(_tokenId);
        Count_Minted.increment();

        //putting it up for sale
        marketItembyId[_tokenId].holder = payable(msg.sender);
        marketItembyId[_tokenId].listed = false;

        // NFT transaction
        IERC721(ScorpionNFTAddr).transferFrom(address(this), msg.sender, _tokenId);

        payable(marketingWallet).transfer(_defaultprice/100*royalties);
        payable(owner()).transfer(_defaultprice/100*(100-royalties));

        addItemsbyHolder(msg.sender, _tokenId);

        emit EV_NFT_Minted(
            _tokenId,
            marketItembyId[_tokenId].level,
            _defaultprice,
            msg.sender,
            false,
            block.timestamp
        );
        
        ScorpionNFT(ScorpionNFTAddr).setApprovalForAll(ScorpionNFTAddr, true);
    }

function mintNFTforList(
        uint32 _tokenId,
        uint256 _price
    ) public payable nonReentrant {
        require(marketItembyId[_tokenId].holder == address(0), "This NFT Id is already minted");

        uint256 _defaultprice = marketItembyId[_tokenId].price;
        require(msg.value >= _defaultprice, "This NFT should be paid to mint");

        ScorpionNFT(ScorpionNFTAddr).mintToken(_tokenId);

        Count_Minted.increment();
        Count_Listed.increment();

        //putting it up for sale
        marketItembyId[_tokenId].holder = payable(msg.sender);
        
        marketItembyId[_tokenId].listed = true;
        marketItembyId[_tokenId].price = _price;

        // NFT transaction
        IERC721(ScorpionNFTAddr).transferFrom(address(this), msg.sender, _tokenId);

        addItemsbyHolder(msg.sender, _tokenId);

        emit EV_NFT_Minted(
            _tokenId,
            marketItembyId[_tokenId].level,
            _defaultprice,
            msg.sender,
            true,
            block.timestamp
        );
        
        ScorpionNFT(ScorpionNFTAddr).setApprovalForAll(ScorpionNFTAddr, true);
    }

    function getTokenURI(uint256 _id) public view returns(string memory) {
        return ScorpionNFT(ScorpionNFTAddr).tokenURI(_id);
    }

    function ownerOf(uint256 _id) public view returns(address){
        return ScorpionNFT(ScorpionNFTAddr).ownerOf(_id);
    }

    function balanceOf(address _addr) public view returns(uint256){
        return ScorpionNFT(ScorpionNFTAddr).balanceOf(_addr);
    }

    function dropNFTById(uint32 _id) public onlyHolder(_id){
        marketItembyId[_id].listed = false;
        Count_Listed.decrement();

        emit EV_NFT_Listed(
            _id,
            marketItembyId[_id].holder,
            marketItembyId[_id].price,
            false,
            block.timestamp
        );
    }

    function updatePriceById(uint32 _id, uint256 _price) public onlyHolder(_id) {
        require(msg.sender == ownerOf(_id), "2.You are not owner of Token.");

        if(marketItembyId[_id].listed == false)
            Count_Listed.increment();

        marketItembyId[_id].listed = true;
        marketItembyId[_id].price = _price;
        
        emit EV_NFT_Listed(
            _id,
            marketItembyId[_id].holder,
            _price,
            true,
            block.timestamp
        );
    }

    function getPriceById(uint32 _id) public view returns (uint256) {
        return marketItembyId[_id].price;
    }

    function purchaseItem(uint32 _id) public payable {
        require(marketItembyId[_id].listed == true, "Not Listed.");
        require(marketItembyId[_id].price <= msg.value, "Not enough BNB to purchase item.");

        IERC721(ScorpionNFTAddr).transferFrom(marketItembyId[_id].holder, msg.sender, _id);

        addItemsbyHolder(msg.sender, _id);
        removeItemsbyHolder(marketItembyId[_id].holder, _id);

        payable(marketItembyId[_id].holder).transfer(marketItembyId[_id].price/100*(98-royalties));
        payable(marketingWallet).transfer(marketItembyId[_id].price/100*royalties);
        payable(owner()).transfer(marketItembyId[_id].price/100*2);

        marketItembyId[_id].holder = payable(msg.sender);
        marketItembyId[_id].listed = false;
        
        Count_Listed.decrement();
        
        ScorpionNFT(ScorpionNFTAddr).setApprovalForAll(ScorpionNFTAddr, true);

        emit EV_NFT_Purchased(
            _id,
            marketItembyId[_id].holder,
            msg.sender,
            marketItembyId[_id].price,
            block.timestamp
        );
    }

    function addItemsbyHolder(address _holder, uint32 _id) private {
        itemsbyHolder[_holder].push(_id);
    }

    function itemsbyholder(address _holder) public view returns (uint32[] memory) {
        return itemsbyHolder[_holder];
    }

    function removeItemsbyHolder(address _holder, uint32 _id) private {
        uint256 _len = itemsbyHolder[_holder].length;
        for (uint256 index = 0; index < _len; index++) {
            if(itemsbyHolder[_holder][index] == _id){
                itemsbyHolder[_holder][index] = itemsbyHolder[_holder][_len-1];
                itemsbyHolder[_holder].pop();
                break;
            }
        }
    }

    // return nfts that the user has purchased
    function fetchMyNFTs(address _holder) public view returns (MarketItem[] memory) {
        uint32[] memory tmp_items = itemsbyholder(_holder);
        MarketItem[] memory items = new MarketItem[](tmp_items.length);
        
        for (uint32 index = 0; index < tmp_items.length; index++) {
            items[index] = marketItembyId[tmp_items[index]];
        }

        return items;
    }

    function setRoyalties(uint256 _royalties) external onlyOwner {
        royalties = _royalties;
    }

    function setNFTPrice(uint256[] memory _price) external onlyOwner {
        nftprice = _price;
    }

    modifier onlyHolder(uint32 _nftId) {
        require(
            msg.sender == marketItembyId[_nftId].holder,
            "Authorization denied"
        );
        _;
    }
}
