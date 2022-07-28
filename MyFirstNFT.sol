// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.2/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.7.2/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.7.2/security/Pausable.sol";
import "@openzeppelin/contracts@4.7.2/access/Ownable.sol";
import "@openzeppelin/contracts@4.7.2/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@4.7.2/utils/Counters.sol";

contract MyFirstNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    uint MAXSUPPLY = 100;
    uint MAXPERWALLET = 2;
    uint tokenCost = 0.1 ether;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyFirstNFT", "MFN") {}

    function _baseURI() internal pure override returns (string memory) {
        return "http://127.0.0.1:8000/metadata/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getMintCost() public view returns(uint) {
        return tokenCost;
    }

    function safeMint() public payable {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAXSUPPLY, 'Mint Supply is over');
        require(tokenCost == msg.value, 'Provide appropriate eth amount');

        address to = _msgSender();
        string memory uri = _baseURI();
        require(balanceOf(to) < MAXPERWALLET, 'Wallet limit over');
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        _setTokenURI(tokenId, uri);
    }

    function safeMintOwner() public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < MAXSUPPLY, 'Mint Supply is over');

        address to = _msgSender();
        string memory uri = _baseURI();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        _setTokenURI(tokenId, uri);

    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

