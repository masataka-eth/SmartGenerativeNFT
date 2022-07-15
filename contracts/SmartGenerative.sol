// SPDX-License-Identifier: MIT
// Copyright (c) 2022 masataka.eth

/*

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

pragma solidity >=0.7.0 <0.9.0;

import './external/erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
//import "hardhat/console.sol"; // Hardhat console log

/**
 * @title SmartGenerative
 * @notice Mint Generative NFT (add RRC721A and WL's MerkleProof)
 */
contract SmartGenerative is ERC721A, Ownable {

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.001 ether;   //!
    uint256 public maxSupply = 1000;   //!
    uint256 public preSaleSupply = 1000;   //!  premint limit
    uint256 public maxMintAmount = 5;   //!
    bool public paused = true;
    bool public onlyWhitelisted = true;
    bytes32 public merkleRoot;

    constructor(
    ) ERC721A('token_name', 'token_symbol') {
        setBaseURI('ipfs://xxxxxxxxxxxxxxxxxxxxxx/');   //!
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    /**
    * @notice Mint from mint site(for WhiteList)
    * @param _mintAmount Amount of mint
    * @param _merkleProof for MerkleProof data
    */
    function premint(uint256 _mintAmount,bytes32[] calldata _merkleProof)public payable{
        require(!onlyWhitelisted, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= preSaleSupply, "pre Sale NFT limit exceeded");

        // Owner also can mint.
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");

            // WhiteList check
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, merkleRoot, leaf),
                "You don't have a whitelist!"
            );

            require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount,"Limit mint amount!");
        }

        _safeMint(msg.sender, _mintAmount);
    } 

    /**
    * @notice Mint from mint site
    * @param _mintAmount Amount of mint
    */
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        // Owner also can mint.
        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        _safeMint(msg.sender, _mintAmount);
    }

    /**
    * @notice Use for airdrop
    * @param _airdropAddresses Airdrop address array
    * @param _UserMintAmount Airdrop amount of mint array
    * @dev onlyOwner
    */
    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    //only owner  
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }    

    function setpreSaleSupply(uint256 _newpreSaleSupply) public onlyOwner {
        preSaleSupply = _newpreSaleSupply;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /**
    * @notice Set WhiteList's merkleRoot
    * @param _merkleRoot Set value
    */
    function setPresaleRoots(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

     /**
    * @notice ERC721A override
    * @return uint256 Return index at 1
    * @dev Changed because ERC721A returns index 0
    */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    
}
