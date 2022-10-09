// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract exnft is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public baseURI;
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public MINT_PRICE = 0.002 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public MAX_PER_WALLET = 10;
    uint256 public CLAIMED_SUPPLY;
    address private contractOwner;

    mapping(address => uint256) private _mintedPerWallet;
    mapping(address => bool) private isFreeClaimed;
    bool public IS_SALE_ACTIVE = false;

    constructor(string memory initBaseURI) ERC721("FinalCaseNFT", "FCNFT"){
        contractOwner = msg.sender;
        baseURI = initBaseURI;
    }

    function publicMint(uint256 count) isSaleActive external payable {
        uint256 cost = (msg.value == 0 && !isFreeClaimed[msg.sender]) && count == MAX_FREE_PER_WALLET ? 0 : MINT_PRICE;
        require(_mintedPerWallet[msg.sender] + count <= MAX_PER_WALLET, "Max per wallet reached");
        require(msg.value >= count * cost, "Please send the exact amount.");
        require(CLAIMED_SUPPLY + count <= MAX_SUPPLY, "Sold out!");

        if(cost == 0){
            isFreeClaimed[msg.sender] = true;
        }else{
            _mintedPerWallet[msg.sender] += count;
        }

        _safeMint(msg.sender, count);
        CLAIMED_SUPPLY += count;
    }


    function toggleSale() public onlyOwner {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while(ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY){
            address currentTokenOwner = ownerOf(currentTokenId);
            if(currentTokenOwner == _owner){
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : "";
    }

    function setMINT_PRICE(uint256 _MINT_PRICE) public onlyOwner {
        MINT_PRICE = _MINT_PRICE;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for(uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier isSaleActive {
        require(IS_SALE_ACTIVE, "Sale not active");
        _;
    }
}
