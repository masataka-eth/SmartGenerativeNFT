// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import './external/erc721a/contracts/ERC721A.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitOpe } from './libs/BitOpe.sol';
//import "hardhat/console.sol"; // Hardhat console log

contract SmartGenerative is ERC721A, Ownable {
    using BitOpe for uint64;
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint
    }

    address public constant withdrawAddress = 0x6A1Ebf8f64aA793b4113E9D76864ea2264A5d482;
    uint256 public maxSupply = 10000;
    uint256 public preLimitMint = 2;
    uint256 public publicMaxMint = 1;
    uint256 public cost = 0.001 ether;
    string public baseURI = "ipfs://xxx/";
    string public baseExtension = ".json";
    bytes32 public merkleRoot = 0;
    uint256 public wlcount = 0; // max:8count(0 - 7)
    Phase public phase = Phase.BeforeMint;
  
    constructor() ERC721A('nft_name', 'nft_symbol') {
        _safeMint(withdrawAddress, 0);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _getAuxforWL(address _owner) internal view returns (uint64) {
        uint64 _auxval = _getAux(_owner);
        return _auxval.get8_forAux(wlcount);
    }

    function _setAuxforWL(address _owner, uint64 _aux) internal{
        uint64 _auxval = _getAux(_owner);
        _setAux(_owner,_auxval.set8_forAux(wlcount,_aux));
    }

    function _setWLmintedCount(address _owner,uint256 _mintAmount) internal{
        uint64 _auxval = _getAuxforWL(_owner);
        unchecked {
            _auxval += uint64(_mintAmount);
        }
        require(_auxval < 256,"minted count is over");
        _setAuxforWL(_owner,_auxval);
    }

    // public---
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function getWLRemain(address _value,uint256 _presaleMax,bytes32[] calldata _merkleProof
    ) public view returns (uint256) {
        uint256 _Amount = 0;
        if(phase == Phase.WLMint){
            if(getWLExit(_value,_presaleMax,_merkleProof) == true){
                if(preLimitMint<_presaleMax){
                    _Amount = preLimitMint - _getAuxforWL(_value);
                }else{
                    _Amount = _presaleMax - _getAuxforWL(_value);
                }
            } 
        }
        return _Amount;
    }

    function getWLExit(address _value,uint256 _presaleMax,bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bool _exit = false;
        bytes32 _leaf = keccak256(abi.encodePacked(_value,_presaleMax));
        if(MerkleProof.verify(_merkleProof, merkleRoot, _leaf) == true){
            _exit = true;
        }
        return _exit;
    }
   
    // modifier for mint---
    modifier isActive(Phase _steage){
        require(phase == _steage,"sale is not active");
        _;
    }

    modifier isCallerisUser(){
        require(tx.origin == msg.sender,"the caller is another controler");
        _;
    }

    modifier isVeryfiyWhiteList(uint256 _mintAmount,uint256 _presaleMax,bytes32[] calldata _merkleProof) {
        require(getWLExit(msg.sender,_presaleMax,_merkleProof),"You don't have a whitelist!");
        require(_mintAmount <= getWLRemain(msg.sender,_presaleMax,_merkleProof), "claim is over max amount at once");
        _;
    }

    modifier isMinAmount(uint256 _mintAmount) {
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _;
    }

    // modifier isMaxAmountAtOnceWL(uint256 _mintAmount,uint256 _presaleMax,bytes32[] calldata _merkleProof) {
    //     require(_mintAmount <= getWLRemain(msg.sender,_presaleMax,_merkleProof), "claim is over max amount at once");
    //     _;
    // }

    modifier isMaxAmountAtOnce(uint256 _mintAmount) {
        require(_mintAmount <=publicMaxMint, "claim is over max amount at once");
        _;
    }
    
    modifier isMaxSupply(uint256 _mintAmount) {
        require(_mintAmount + totalSupply() <= maxSupply, "claim is over the max supply");
        _;
    }

    modifier isEnoughEth(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "not enough eth");
        _;
    }

    // mint
    function mint_onlywl(uint256 _mintAmount,uint256 _presaleMax,bytes32[] calldata _merkleProof)public payable
        isActive(Phase.WLMint)
        isCallerisUser()
        isVeryfiyWhiteList(_mintAmount,_presaleMax,_merkleProof)
        isMinAmount(_mintAmount)
        //isMaxAmountAtOnceWL(_mintAmount,_presaleMax,_merkleProof)
        isMaxSupply(_mintAmount)
        isEnoughEth(_mintAmount){
        
        _setWLmintedCount(msg.sender, _mintAmount);
        _safeMint(msg.sender, _mintAmount);
    } 

    function mint(uint256 _mintAmount) public payable
        isActive(Phase.PublicMint)
        isCallerisUser()
        isMinAmount(_mintAmount)
        isMaxAmountAtOnce(_mintAmount)
        isMaxSupply(_mintAmount)
        isEnoughEth(_mintAmount){

        _safeMint(msg.sender, _mintAmount);
    }
   
    // onlyOwner
    function setMaxSupply(uint256 _value) public onlyOwner {
        maxSupply = _value;
    }

    function setCost(uint256 _value) public onlyOwner {
        cost = _value;
    }

    function setmaxMintAmount(uint256 _value) public onlyOwner {
        publicMaxMint = _value;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setPhase(Phase _newPhase) public onlyOwner {
        require( _newPhase <= Phase.PublicMint,"no Valid");
        phase = _newPhase;
    }
    function setWlcount(uint256 _value) public onlyOwner {
        require( 0 <= _value && _value < 8,"no Valid(0-7)");
        wlcount = _value;
    }
 
    function withdraw() external onlyOwner {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }   
}
