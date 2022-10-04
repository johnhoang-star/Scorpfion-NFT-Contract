//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ScorpionNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public _scorpURI;

    constructor() ERC721("ScorpionFinanceNFT", "ScorpFIN") {

    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        uint256 tmpid = tokenId - 1;

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tmpid.toString(), ".json")) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */

    function _setbaseURI(string memory str) public onlyOwner {
        _scorpURI = str;
    }

    function _baseURI() internal view override returns (string memory) {
        return _scorpURI;
    }

    function mintToken(uint256 id) public {
        _mint(msg.sender, id);
    }
}
