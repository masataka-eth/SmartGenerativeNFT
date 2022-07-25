// SPDX-License-Identifier: MIT
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
    //address public constant withdrawAddress = 0x6A1Ebf8f64aA793b4113E9D76864ea2264A5d482;
    uint256 public cost = 0.001 ether;
    uint256 public maxSupply = 20;
    uint256 public maxMintAmount = 5;
    uint256 public premaxMintAmount = 10;
    bool public paused = true;
    bool public isOnlyWhitelisted = true;
    bytes32 public merkleRoot = 0;

    string public baseURI = "";
    string public baseExtension = ".json";

    constructor() ERC721A('nft_name', 'nft_symbol') {
        //setBaseURI('ipfs://xxxxxxxxxxxxxxxxxxxxxx/');
        //_safeMint(withdrawAddress, 0);
    }

    // public---
    function getMaxMintAmount() public view returns (uint256) {
        if (isOnlyWhitelisted == true) {
            return premaxMintAmount;
        } else {
            return maxMintAmount;
        }
    }

    function getRemainMintAmountWL(address value,bytes32[] calldata _merkleProof) public view returns (uint256) {
        uint256 _MintedCount = balanceOf(value);
        uint256 _MaxCount = premaxMintAmount;
        uint256 _Amount = 0;
        if (isOnlyWhitelisted == true){
            if(getWhitelistExit(value,_merkleProof) == true){
                if(_MintedCount < _MaxCount){
                    _Amount = _MaxCount - _MintedCount;
                }
            }
        }
        return _Amount;
    }

    function getRemainMintAmount(address value) public view returns (uint256) {
        uint256 _MintedCount = balanceOf(value);
        uint256 _MaxCount = maxMintAmount;
        uint256 _Amount = 0;
        if (isOnlyWhitelisted == false){
            if(_MintedCount < _MaxCount){
                _Amount = _MaxCount - _MintedCount;
            }
        }
        return _Amount;
    }

    function getWhitelistExit(address value,bytes32[] calldata _merkleProof)public view returns (bool) {
        bool _exit = false;
        bytes32 _leaf = keccak256(abi.encodePacked(value));
        if(MerkleProof.verify(_merkleProof, merkleRoot, _leaf) == true){
            _exit = true;
        }
        return _exit;
    }
   
    // modifier---
    modifier mintPaused() {
        require(!paused, "mint is paused");
        _;
    }

    modifier isOnlyWhitelist(){
        require(isOnlyWhitelisted,"OnlyWhitelisted");
        _;
    }

    modifier isNotOnlyWhitelist(){
        require(!isOnlyWhitelisted,"Not OnlyWhitelisted");
        _;
    }
    modifier isVeryfiyWhiteList(bytes32[] calldata _merkleProof) {
        require(getWhitelistExit(msg.sender,_merkleProof),"You don't have a whitelist!");
        _;
    }

    modifier isMinAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _;
    }

    modifier isMaxAmountAtOnceWL(uint256 _mintAmount,bytes32[] calldata _merkleProof) {
        require(_mintAmount <= getRemainMintAmountWL(msg.sender,_merkleProof), "claim is over max amount at once");
        _;
    }

    modifier isMaxAmountAtOnce(uint256 _mintAmount) {
        require(_mintAmount <= getRemainMintAmount(msg.sender), "claim is over max amount at once");
        _;
    }
    
    modifier isMaxSupply(uint256 _mintAmount) {
        require(_mintAmount + totalSupply() <= maxSupply, "claim is over the max supply");
        _;
    }

    modifier isLimitAmount(uint256 _mintAmount) {
        require(balanceOf(msg.sender) + _mintAmount <= getMaxMintAmount(),"Limit mint amount!");
        _;
    }

    modifier isEnoughEth(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "not enough eth");
        _;
    }

    /**
    * @notice Mint from mint site(for WhiteList)
    * @param _mintAmount Amount of mint
    * @param _merkleProof for MerkleProof data
    */
    function mint_onlywl(uint256 _mintAmount,bytes32[] calldata _merkleProof)public payable
        mintPaused
        isOnlyWhitelist
        isVeryfiyWhiteList(_merkleProof)
        isMinAmount(_mintAmount)
        isMaxAmountAtOnceWL(_mintAmount,_merkleProof)
        isMaxSupply(_mintAmount)
        isLimitAmount(_mintAmount)
        isEnoughEth(_mintAmount){

        _safeMint(msg.sender, _mintAmount);
    } 

    /**
    * @notice Mint from mint site
    * @param _mintAmount Amount of mint
    */
    function mint(uint256 _mintAmount) public payable
        mintPaused
        isNotOnlyWhitelist
        isMinAmount(_mintAmount)
        isMaxAmountAtOnce(_mintAmount)
        isMaxSupply(_mintAmount)
        isLimitAmount(_mintAmount)
        isEnoughEth(_mintAmount){

        _safeMint(msg.sender, _mintAmount);
    }
   
    // only owner--- 
    // /**
    // * @notice Use for airdrop
    // * @param _airdropAddresses Airdrop address array
    // * @param _UserMintAmount Airdrop amount of mint array
    // * @dev onlyOwner
    // */
    // function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
    //     uint256 supply = totalSupply();
    //     uint256 _mintAmount = 0;
    //     for (uint256 i = 0; i < _UserMintAmount.length; i++) {
    //         _mintAmount += _UserMintAmount[i];
    //     }
    //     require(_mintAmount > 0, "need to mint at least 1 NFT");
    //     require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    //     for (uint256 i = 0; i < _UserMintAmount.length; i++) {
    //         _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
    //     }
    // }

    function setMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
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

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        isOnlyWhitelisted = _state;
    }   
 
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /**
    * @notice Set WhiteList's merkleRoot
    * @param _merkleRoot Always set value in advance (if onlyWL)
    */
    function setPresaleRoots(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    // ovverride---
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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
